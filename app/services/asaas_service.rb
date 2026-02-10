require 'net/http'
require 'uri'
require 'json'

class AsaasService
  def initialize
    # 1. Carrega configurações
    config = Rails.configuration.asaas
    @api_key = config[:api_key].to_s.strip
    @base_url = config[:url]

    # 2. Debug Inicial
    puts "\n--- Verificação Asaas ---"
    puts "🚀 Conectando em: #{@base_url}"
    if @api_key.present?
      puts "🔑 Chave identificada: #{@api_key[0..12]}..."
    else
      puts "❌ ERRO: Chave de API não encontrada em Rails.configuration.asaas"
    end
    puts "------------------------\n"
  end

  # Atualizado para aceitar Método de Pagamento e Parcelas
  # payment_method: 'PIX', 'BOLETO', 'CREDIT_CARD' ou 'UNDEFINED' (cliente escolhe)
  # installments: Inteiro (1 = à vista, >1 = parcelado)
  def create_payment_url(user, value_float, description, external_id, redirect_url, payment_method = 'UNDEFINED', installments = 1)

    customer_id = find_or_create_customer(user)
    return nil unless customer_id

    # Garante que o método seja válido e maiúsculo
    billing_type = ['PIX', 'BOLETO', 'CREDIT_CARD', 'UNDEFINED'].include?(payment_method.to_s.upcase) ? payment_method.to_s.upcase : 'UNDEFINED'

    # Tratamento de Parcelamento
    installments = installments.to_i
    installments = 1 if installments < 1

    payload = {
      customer: customer_id,
      billingType: billing_type,
      dueDate: (Date.today + 1.day).to_s,
      description: description,
      postalService: false,
      externalReference: external_id.to_s
    }

    if installments > 1
      # LÓGICA DE PARCELAMENTO
      # No Asaas, mandamos o valor da PARCELA e o número de parcelas
      valor_parcela = (value_float / installments).round(2)

      payload[:installmentCount] = installments
      payload[:installmentValue] = valor_parcela

      puts "📅 Configurando parcelamento: #{installments}x de R$ #{valor_parcela} via #{billing_type}"
    else
      # PAGAMENTO À VISTA
      payload[:value] = value_float
    end

    # Envia Requisição
    response = request(:post, "/payments", payload)

    if response && response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)

      # Retorna o link. Se for boleto/parcelado, o Asaas retorna o link da primeira cobrança ou do carnê.
      return json['invoiceUrl']
    else
      msg_erro = response ? response.body.force_encoding('UTF-8') : "Sem resposta"
      puts "🔴 ERRO PAGAMENTO: #{msg_erro}"
      nil
    end
  end

  private

  def find_or_create_customer(user)
    email = user.email.strip
    encoded_email = URI.encode_www_form_component(email)

    # 1. Busca Cliente
    response = request(:get, "/customers?email=#{encoded_email}")

    if response && response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)['data']
      return data.first['id'] if data && data.any?
    end

    # 2. Cria Cliente
    nome = user.email.split('@').first.gsub(/\d/, '')
    nome = "Cliente #{user.id}" if nome.to_s.strip.empty?
    cpf = user.documento_numero.to_s.gsub(/\D/, '')

    payload = {
      name: nome,
      email: email,
      cpfCnpj: cpf,
      externalReference: user.id.to_s
    }

    create_resp = request(:post, "/customers", payload)

    if create_resp && create_resp.is_a?(Net::HTTPSuccess)
      return JSON.parse(create_resp.body)['id']
    else
      msg_erro = create_resp ? create_resp.body.force_encoding('UTF-8') : "Erro na criação do cliente"
      puts "🔴 ERRO CLIENTE: #{msg_erro}"
      nil
    end
  end

  def request(method, endpoint, body = nil)
    uri = URI.parse("#{@base_url}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    if method == :get
      req = Net::HTTP::Get.new(uri.request_uri)
    else
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = body.to_json if body
    end

    req['access_token'] = @api_key
    req['Content-Type'] = 'application/json'

    http.request(req)
  rescue => e
    puts "💥 ERRO DE REDE: #{e.message}"
    nil
  end
end