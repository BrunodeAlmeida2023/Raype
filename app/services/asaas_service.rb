require 'net/http'
require 'uri'
require 'json'

class AsaasService
  def initialize
    # 1. Carrega configurações
    config = Rails.configuration.asaas
    @api_key = config[:api_key].to_s.strip
    @base_url = config[:url]

    # 2. Debug Inicial (Apenas no console do servidor)
    puts "\n--- Inicializando AsaasService ---"
    if @api_key.present?
      puts "🔑 Chave identificada: #{@api_key[0..5]}...******"
    else
      puts "❌ ERRO: Chave de API não encontrada em Rails.configuration.asaas"
    end
  end

  # Cria a URL de pagamento
  def create_payment_url(user, value_float, description, external_id, redirect_url, payment_method = 'UNDEFINED', installments = 1)
    # 1. Busca ou cria o cliente no Asaas
    customer_id = find_or_create_customer(user)
    return nil unless customer_id

    # 2. Normaliza os dados
    raw_method = payment_method.to_s.upcase
    installments = installments.to_i
    installments = 1 if installments < 1
    value_float = value_float.to_f

    Rails.logger.info "💳 Processamento: #{raw_method} | Parcelas: #{installments} | Valor: R$ #{value_float}"

    # 3. Determina billingType para o Asaas
    billing_type = case raw_method
                   when 'CREDIT_CARD', 'DEBIT_CARD', 'CARD'
                     'CREDIT_CARD' # Asaas decide crédito ou débito na tela deles
                   when 'PIX'
                     'PIX'
                   when 'BOLETO'
                     'BOLETO'
                   else
                     'UNDEFINED' # Link genérico (Asaas mostra todas as opções)
                   end

    # 4. Tratamento ESPECIAL: Boleto Parcelado (Carnê)
    if raw_method == 'BOLETO' && installments > 1
      Rails.logger.info "📄 Criando carnê de boletos: #{installments}x"
      return create_boleto_installments(customer_id, value_float, description, external_id, installments)
    end

    # 5. Validação de valor mínimo
    min_value = (billing_type == 'PIX') ? 0.50 : 5.00
    if value_float < min_value
      Rails.logger.error "❌ Valor R$ #{value_float} abaixo do mínimo (R$ #{min_value})"
      return nil
    end

    # 6. Monta payload
    payload = {
      customer: customer_id,
      billingType: billing_type,
      value: value_float,
      dueDate: (Date.today + 1.day).to_s,
      description: description,
      postalService: false,
      externalReference: external_id.to_s
    }

    # Para cartão, adiciona nota sobre parcelamento (opcional)
    if billing_type == 'CREDIT_CARD' && installments > 1
      payload[:description] += " (sugestão: #{installments}x)"
    end

    Rails.logger.debug "📦 Payload: #{payload.to_json}"

    # 7. Envia para Asaas
    response = request(:post, "/payments", payload)

    if response && response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      invoice_url = json['invoiceUrl']
      Rails.logger.info "✅ Link gerado: #{invoice_url}"
      return invoice_url
    else
      log_error(response)
      return nil
    end
  end

  private

  # Cria múltiplos boletos (Carnê)
  def create_boleto_installments(customer_id, total_value, description, external_id, installments)
    valor_parcela = (total_value / installments).round(2)

    # Validação Asaas para boleto
    if valor_parcela < 5.00
      Rails.logger.error "❌ Valor da parcela (R$ #{valor_parcela}) abaixo do mínimo para boleto (R$ 5,00)"
      return nil
    end

    puts "📋 Iniciando criação de carnê: #{installments}x de R$ #{valor_parcela}"

    payment_urls = []

    installments.times do |i|
      parcela_num = i + 1
      due_date = (Date.today + parcela_num.months).to_s

      payload = {
        customer: customer_id,
        billingType: 'BOLETO',
        value: valor_parcela,
        dueDate: due_date,
        description: "#{description} - Parc. #{parcela_num}/#{installments}",
        postalService: false,
        externalReference: "#{external_id}_parc_#{parcela_num}"
      }

      response = request(:post, "/payments", payload)

      if response && response.is_a?(Net::HTTPSuccess)
        json = JSON.parse(response.body)
        payment_urls << json['invoiceUrl']
        puts "   -> Parcela #{parcela_num} criada: #{json['id']}"
      else
        puts "   -> Erro na parcela #{parcela_num}"
        log_error(response)
        return nil # Aborta se uma falhar para não gerar carnê incompleto
      end
    end

    # Retorna o link da primeira parcela (ou você poderia retornar uma página com todos os links)
    puts "✅ Carnê finalizado com sucesso."
    return payment_urls.first
  end

  def find_or_create_customer(user)
    email = user.email.strip

    # 1. Tenta buscar pelo email
    encoded_email = URI.encode_www_form_component(email)
    response = request(:get, "/customers?email=#{encoded_email}")

    if response && response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)['data']
      if data && data.any?
        return data.first['id']
      end
    end

    # 2. Se não achar, cria novo
    nome = user.email.split('@').first
    cpf = user.respond_to?(:documento_numero) ? user.documento_numero.to_s.gsub(/\D/, '') : ""

    # Payload criação cliente
    payload = {
      name: nome,
      email: email,
      externalReference: user.id.to_s
    }
    payload[:cpfCnpj] = cpf if cpf.present?

    create_resp = request(:post, "/customers", payload)

    if create_resp && create_resp.is_a?(Net::HTTPSuccess)
      return JSON.parse(create_resp.body)['id']
    else
      log_error(create_resp, "Erro ao criar cliente")
      nil
    end
  end

  def request(method, endpoint, body = nil)
    uri = URI.parse("#{@base_url}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request_obj = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)

    request_obj['access_token'] = @api_key
    request_obj['Content-Type'] = 'application/json'
    request_obj.body = body.to_json if body

    begin
      http.request(request_obj)
    rescue StandardError => e
      Rails.logger.error "💥 AsaasService Exception: #{e.message}"
      nil
    end
  end

  def log_error(response, context = "Erro Asaas")
    if response
      begin
        body = JSON.parse(response.body)
        errors = body['errors']&.map { |e| e['description'] }&.join(', ')
        Rails.logger.error "🔴 #{context} (Status #{response.code}): #{errors || response.body}"
      rescue
        Rails.logger.error "🔴 #{context} (Status #{response.code}): #{response.body}"
      end
    else
      Rails.logger.error "🔴 #{context}: Sem resposta da API"
    end
  end
end