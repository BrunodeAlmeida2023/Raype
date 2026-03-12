class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rent, only: [:show, :process_payment], if: -> { params[:rent_id].present? }
  before_action :load_checkout_data, only: [:new, :create_payment]

  # Nova rota para exibir checkout SEM rent criado
  def new
    unless @checkout_data
      redirect_to root_path, alert: "Sessão expirada. Por favor, finalize o orçamento novamente."
      return
    end

    @outdoor = Outdoor.find(@checkout_data[:outdoor_id])

    # 🔒 VALIDAÇÃO: Verifica se a localização foi bloqueada pelo admin
    if @outdoor.outdoor_location.present? &&
       LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, @checkout_data[:start_date], @checkout_data[:end_date])
      next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
      session.delete(:pending_checkout)
      redirect_to find_date_home_path, alert: "Este período não está mais disponível. " \
                                              "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. " \
                                              "Por favor, selecione outra data e refaça o orçamento."
      return
    end
  end

  # Rota antiga para exibir checkout COM rent já criado
  def show
    # Se o rent já foi pago, redireciona para a página de status
    if @rent.status == 'paid'
      redirect_to order_status_path(@rent.id), notice: "Este pedido já foi pago."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se a localização ou faces foram bloqueadas pelo admin
    if @rent.blocked_by_admin?
      @rent.update!(status: 'canceled')

      # Verifica se é bloqueio de faces específicas
      if @rent.faces_blocked_by_admin?
        blocked_faces = LocationBlockedFace.blocked_faces_in_period(
          @rent.outdoor.outdoor_location,
          @rent.start_date,
          @rent.end_date
        )
        selected_blocked = @rent.outdoor.selected_faces & blocked_faces

        redirect_to root_path, alert: "As face(s) #{selected_blocked.join(', ')} do outdoor selecionado não estão mais disponíveis. " \
                                      "Seu orçamento foi cancelado automaticamente. " \
                                      "Por favor, selecione outras faces ou outro período."
        return
      else
        # Bloqueio de localização completa
        next_available = LocationBlockedDate.minimum_start_date_for_location(@rent.outdoor.outdoor_location)
        redirect_to root_path, alert: "Este período não está mais disponível para a localização selecionada. " \
                                      "Seu orçamento foi cancelado automaticamente. " \
                                      "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}."
        return
      end
    end

    # Exibe a página de checkout com os métodos de pagamento
    @outdoor = @rent.outdoor
  end

  # Nova ação para criar pagamento SEM rent existente
  def create_payment
    unless @checkout_data
      redirect_to root_path, alert: "Sessão expirada. Por favor, finalize o orçamento novamente."
      return
    end

    payment_method = params[:payment_method].to_s.upcase
    installments = params[:installments].to_i > 0 ? params[:installments].to_i : 1

    Rails.logger.info "🔵 PROCESSANDO: Método=#{payment_method} | Parcelas=#{installments}"

    # Valida método
    valid_methods = ['PIX', 'BOLETO', 'CREDIT_CARD', 'DEBIT_CARD']
    unless valid_methods.include?(payment_method)
      redirect_to new_checkout_path, alert: "Método de pagamento inválido." and return
    end

    # Regras específicas por método
    case payment_method
    when 'CREDIT_CARD', 'DEBIT_CARD'
      installments = 1
    when 'BOLETO'
      installments = 12 if installments > 12
    when 'PIX'
      # PIX: Mantém o installments para suportar PIX parcelado
      max_allowed = @checkout_data[:quantity_months].to_i
      installments = max_allowed if installments > max_allowed
    end

    Rails.logger.info "🔵 ENVIANDO PARA ASAAS: Método=#{payment_method} | Parcelas=#{installments}"

    # PRIMEIRO: Cria o rent (para ter o ID)
    @outdoor = Outdoor.find(@checkout_data[:outdoor_id])

    # 🔒 VALIDAÇÃO: Verifica se a localização está bloqueada pelo admin antes de criar o rent
    if @outdoor.outdoor_location.present? &&
       LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, @checkout_data[:start_date], @checkout_data[:end_date])
      next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
      session.delete(:pending_checkout)
      redirect_to find_date_home_path, alert: "Este período não está mais disponível. " \
                                              "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. " \
                                              "Por favor, selecione outra data e refaça o orçamento."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se as faces específicas estão bloqueadas pelo admin
    if @outdoor.outdoor_location.present? && @outdoor.selected_faces.present?
      blocked_faces = LocationBlockedFace.blocked_faces_in_period(
        @outdoor.outdoor_location,
        @checkout_data[:start_date],
        @checkout_data[:end_date]
      )

      selected_blocked = @outdoor.selected_faces & blocked_faces
      if selected_blocked.any?
        session.delete(:pending_checkout)
        redirect_to find_date_home_path, alert: "Face(s) #{selected_blocked.join(', ')} não está(ão) mais disponível(is). " \
                                                "Por favor, selecione outras faces e refaça o orçamento."
        return
      end
    end

    @rent = Rent.new(
      user: current_user,
      outdoor: @outdoor,
      start_date: @checkout_data[:start_date],
      end_date: @checkout_data[:end_date],
      total_amount: @checkout_data[:total_amount],
      status: 'pending'
      # payment_method será preenchido pelo webhook com o método REAL usado
    )

    unless @rent.save
      redirect_to new_checkout_path, alert: "Erro ao criar pedido: #{@rent.errors.full_messages.join(', ')}"
      return
    end

    Rails.logger.info "✅ Rent ##{@rent.id} criado"

    # SEGUNDO: Gera o link no Asaas usando o rent.id como external_reference
    asaas = AsaasService.new
    url_retorno_whatsapp = pedido_whatsapp_url(@rent.id, host: request.base_url)

    link_pagamento = asaas.create_payment_url(
      current_user,
      @checkout_data[:total_amount],
      "Aluguel Outdoor ##{@rent.id} - #{@outdoor.outdoor_type}",
      @rent.id, # USA O ID DO RENT COMO EXTERNAL REFERENCE
      url_retorno_whatsapp,
      payment_method,
      installments
    )

    if link_pagamento.blank?
      # Se falhar, deleta o rent criado
      @rent.destroy
      redirect_to new_checkout_path, alert: "Erro ao gerar link de pagamento. Tente novamente."
      return
    end

    # TERCEIRO: Atualiza o rent com o link
    @rent.update(asaas_payment_url: link_pagamento)

    # Limpa a session
    session.delete(:pending_checkout)

    Rails.logger.info "✅ Link gerado e salvo: #{link_pagamento}"

    # Redireciona para o link de pagamento
    redirect_to link_pagamento, allow_other_host: true
  end

  # Ação antiga para processar pagamento COM rent existente
  def process_payment
    payment_method = params[:payment_method].to_s.upcase
    installments = params[:installments].to_i > 0 ? params[:installments].to_i : 1

    Rails.logger.info "🔵 PROCESSANDO: Método=#{payment_method} | Parcelas=#{installments}"

    # Valida método
    valid_methods = ['PIX', 'BOLETO', 'CREDIT_CARD', 'DEBIT_CARD']
    unless valid_methods.include?(payment_method)
      redirect_to checkout_path(@rent.id), alert: "Método de pagamento inválido." and return
    end

    # Regras específicas por método
    case payment_method
    when 'CREDIT_CARD', 'DEBIT_CARD'
      installments = 1
    when 'BOLETO'
      installments = 12 if installments > 12
    when 'PIX'
      # PIX: Mantém o installments para suportar PIX parcelado
      # Calcula o limite baseado no período do rent
      months_rented = ((@rent.end_date.year * 12 + @rent.end_date.month) - (@rent.start_date.year * 12 + @rent.start_date.month))
      max_allowed = [months_rented, 12].min
      installments = max_allowed if installments > max_allowed
    end

    Rails.logger.info "🔵 ENVIANDO PARA ASAAS: Método=#{payment_method} | Parcelas=#{installments}"

    # 🔒 VALIDAÇÃO: Verifica se a localização foi bloqueada pelo admin após a criação do rent
    if @rent.blocked_by_admin?
      next_available = LocationBlockedDate.minimum_start_date_for_location(@rent.outdoor.outdoor_location)
      @rent.update!(status: 'canceled')
      redirect_to root_path, alert: "Este período não está mais disponível para a localização selecionada. " \
                                    "Seu orçamento foi cancelado automaticamente. " \
                                    "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. " \
                                    "Por favor, crie um novo orçamento com outras datas."
      return
    end

    # URL de retorno
    url_retorno_whatsapp = pedido_whatsapp_url(@rent.id, host: request.base_url)

    # Serviço Asaas
    asaas = AsaasService.new
    link_pagamento = asaas.create_payment_url(
      current_user,
      @rent.total_amount,
      "Aluguel Outdoor ##{@rent.id}",
      @rent.id,
      url_retorno_whatsapp,
      payment_method,
      installments
    )

    if link_pagamento.present?
      # Salva o link de pagamento no rent para futuro acesso
      # payment_method será preenchido pelo webhook com o método REAL usado
      @rent.update(asaas_payment_url: link_pagamento)
      redirect_to link_pagamento, allow_other_host: true
    else
      redirect_to checkout_path(@rent.id), alert: "Erro no Asaas. Tente novamente."
    end
  end

  def success
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:id]) if params[:id]
  end

  def order_status
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:id])

    unless @rent
      redirect_to root_path, alert: "Pedido não encontrado."
      return
    end

    # Verifica se o rent pendente foi bloqueado pelo admin (localização bloqueada depois do orçamento)
    @location_blocked = @rent.pending? && @rent.blocked_by_admin?
  end

  def cancel_order
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:id])

    unless @rent
      redirect_to root_path, alert: "Pedido não encontrado."
      return
    end

    # Só permite cancelar pedidos pendentes
    unless @rent.status == 'pending'
      redirect_to order_status_path(@rent.id), alert: "Não é possível cancelar este pedido."
      return
    end

    # Deleta o rent do banco de dados
    if @rent.destroy
      redirect_to root_path, notice: "Orçamento cancelado com sucesso. Você pode criar um novo orçamento agora."
    else
      redirect_to order_status_path(@rent.id), alert: "Erro ao cancelar orçamento. Tente novamente."
    end
  end

  private

  def load_checkout_data
    @checkout_data = session[:pending_checkout]
    if @checkout_data
      @checkout_data = @checkout_data.with_indifferent_access
      @checkout_data[:start_date] = Date.parse(@checkout_data[:start_date]) if @checkout_data[:start_date].is_a?(String)
      @checkout_data[:end_date] = Date.parse(@checkout_data[:end_date]) if @checkout_data[:end_date].is_a?(String)
    end
  end

  def set_rent
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:rent_id])

    unless @rent
      redirect_to root_path, alert: "Pedido não encontrado."
    end
  end
end