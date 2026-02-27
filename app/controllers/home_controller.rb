class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :set_outdoor, only: [:find_outdoor, :find_date, :choose_art, :finalize_budget]

  def index
    @user = current_user
    @outdoor = current_user.outdoor

    # 🔒 Se o outdoor tem datas salvas que agora estão bloqueadas, limpa as datas automaticamente
    if @outdoor && outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_quantity_month: nil)
      flash.now[:alert] = "As datas selecionadas não estão mais disponíveis. Por favor, selecione novas datas."
    end
  end

  def show
    redirect_to root_path
  end

  def find_outdoor
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def find_date
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # 🔒 Se a data salva agora está bloqueada, limpa para forçar nova seleção
    if outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_quantity_month: nil)
      flash.now[:alert] = "As datas selecionadas anteriormente não estão mais disponíveis. Por favor, selecione novas datas."
    end

    # @outdoor já está setado pelo before_action
  end

  def choose_art
    # Bloqueia se tem rent pendente ou pago
    if current_user.rents.where(status: ['pending', 'paid']).exists?
      rent = current_user.rents.where(status: ['pending', 'paid']).first
      if rent.status == 'paid'
        redirect_to root_path, alert: "Você já possui um pedido pago. Não é possível alterar as informações. Entre em contato via WhatsApp se precisar."
      else
        redirect_to order_status_path(rent.id), alert: "Você possui um pedido pendente. Cancele-o antes de fazer alterações."
      end
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def finalize_budget
    # Verifica se o usuário já possui um orçamento pago
    paid_rent = current_user.rents.where(status: 'paid').first

    if paid_rent.present?
      whatsapp_message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{paid_rent.id}). Gostaria de enviar as informações para impressão."
      whatsapp_url = "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(whatsapp_message)}"
      redirect_to whatsapp_url, allow_other_host: true, alert: "Você já possui um pedido pago. Entre em contato via WhatsApp para enviar suas informações."
      return
    end

    # Verifica se o usuário já possui um orçamento pendente
    existing_rent = current_user.rents.where(status: 'pending').first

    if existing_rent.present?
      redirect_to order_status_path(existing_rent.id), alert: "Você já possui um orçamento pendente. Finalize ou cancele-o antes de criar um novo."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se as datas salvas agora estão bloqueadas
    if outdoor_dates_blocked?(@outdoor)
      @outdoor.update(selected_start_date: nil, selected_quantity_month: nil)
      redirect_to find_date_home_path, alert: "As datas selecionadas não estão mais disponíveis. Por favor, selecione novas datas."
      return
    end

    # @outdoor já está setado pelo before_action
  end

  def post_find_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor


    if @outdoor.update(outdoor_params)
      flash[:notice] = "Outdoor salvo com sucesso!"
      redirect_to root_path
    else
      flash[:alert] = "Erro ao salvar outdoor: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to find_outdoor_home_path
    end
  end

  def post_find_date
    @outdoor = current_user.outdoor || current_user.build_outdoor

    start_date = params[:selected_start_date]
    quantity_month = params[:selected_quantity_month]

    # Validação no backend: data final deve ser no mínimo 1 mês após a data inicial
    if start_date.present? && quantity_month.present?
      puts "Start Date: #{start_date}, Quantity Month: #{quantity_month.to_i}"
      if quantity_month.to_i < 1
        flash[:alert] = "A data final deve ser no mínimo 1 mês após a data inicial."
        redirect_to find_date_home_path
        return
      end

      # 🔒 VALIDAÇÃO: Verifica se o período está bloqueado (por outdoor individual)
      start_date_parsed = Date.parse(start_date)
      end_date_calculated = start_date_parsed + quantity_month.to_i.months

      if OutdoorBlockedDate.blocked_between?(@outdoor.id, start_date_parsed, end_date_calculated)
        flash[:alert] = "Este período não está disponível. Há datas bloqueadas no intervalo selecionado. Por favor, escolha outras datas."
        redirect_to find_date_home_path
        return
      end

      # 🔒 VALIDAÇÃO: Verifica se a LOCALIZAÇÃO está bloqueada pelo admin (clientes presenciais)
      if @outdoor.outdoor_location.present? &&
         LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, start_date_parsed, end_date_calculated)
        next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
        flash[:alert] = "Este período não está disponível para a localização selecionada. " \
                        "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. Por favor, escolha outra data."
        redirect_to find_date_home_path
        return
      end
    end

    if @outdoor.update(selected_start_date: start_date, selected_quantity_month: quantity_month)
      flash[:notice] = "Data salva com sucesso!"
      redirect_to root_path
    else
      flash[:alert] = "Erro ao salvar data: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to find_date_home_path
    end
  end

  def post_choose_art
    @outdoor = current_user.outdoor || current_user.build_outdoor

    # Log dos parâmetros recebidos
    Rails.logger.info "🎨 post_choose_art - Params recebidos:"
    Rails.logger.info "   art_quantity: #{params[:art_quantity]}"
    Rails.logger.info "   custom_art_quantity: #{params[:custom_art_quantity]}"

    # Salva a quantidade de artes
    art_qty = params[:art_quantity].to_i
    @outdoor.art_quantity = art_qty

    # Salva a quantidade de artes customizadas se art_quantity = 0
    if art_qty == 0
      custom_qty = params[:custom_art_quantity].to_s.strip
      Rails.logger.info "   custom_art_quantity (stripped): '#{custom_qty}'"

      if custom_qty.present? && custom_qty != '' && custom_qty.to_i > 0
        @outdoor.custom_art_quantity = custom_qty.to_i
        Rails.logger.info "   ✅ custom_art_quantity será salvo como: #{@outdoor.custom_art_quantity}"
      else
        # Se não selecionou, mostra erro
        Rails.logger.warn "   ❌ custom_art_quantity não fornecido ou inválido"
        flash[:alert] = "Por favor, selecione quantas artes você deseja que criemos para você."
        redirect_to choose_art_home_path
        return
      end
    else
      # Se art_quantity > 0, limpa custom_art_quantity
      @outdoor.custom_art_quantity = nil
      Rails.logger.info "   ℹ️  custom_art_quantity será limpo (art_quantity > 0)"
    end

    # Anexa as artes se foram enviadas
    if params[:art_files].present?
      # Remove artes antigas antes de adicionar novas
      @outdoor.art_files.purge if @outdoor.art_files.attached?

      params[:art_files].each do |art_file|
        @outdoor.art_files.attach(art_file) if art_file.present?
      end
      Rails.logger.info "   📎 Artes anexadas"
    end

    if @outdoor.save
      @outdoor.reload
      Rails.logger.info "   ✅ Outdoor salvo! custom_art_quantity final: #{@outdoor.custom_art_quantity.inspect}"
      flash[:notice] = "Arte salva com sucesso!"
      redirect_to root_path
    else
      Rails.logger.error "   ❌ Erro ao salvar: #{@outdoor.errors.full_messages.join(', ')}"
      flash[:alert] = "Erro ao salvar arte: #{@outdoor.errors.full_messages.join(', ')}"
      redirect_to choose_art_home_path
    end
  end

  # app/controllers/home_controller.rb

  def post_finalize_budget
    # Verifica se o usuário já possui um orçamento pago
    paid_rent = current_user.rents.where(status: 'paid').first

    if paid_rent.present?
      whatsapp_message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{paid_rent.id}). Gostaria de enviar as informações para impressão."
      whatsapp_url = "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(whatsapp_message)}"
      redirect_to whatsapp_url, allow_other_host: true, alert: "Você já possui um pedido pago. Entre em contato via WhatsApp para enviar suas informações."
      return
    end

    # Verifica se o usuário já possui um orçamento pendente
    existing_rent = current_user.rents.where(status: 'pending').first

    if existing_rent.present?
      redirect_to order_status_path(existing_rent.id), alert: "Você já possui um orçamento pendente. Finalize ou cancele-o antes de criar um novo."
      return
    end

    # 🔒 SEGURANÇA: Sempre usa outdoor do current_user (nunca aceita outdoor_id do frontend)
    @outdoor = current_user.outdoor

    unless @outdoor
      redirect_to root_path, alert: "Nenhum outdoor encontrado. Complete o processo de seleção primeiro."
      return
    end

    # Validação: Outdoor deve estar completo
    unless @outdoor.outdoor_type.present? && @outdoor.selected_start_date.present? && @outdoor.selected_quantity_month.present?
      redirect_to root_path, alert: "Complete todas as etapas antes de finalizar o orçamento."
      return
    end

    # 🔒 VALIDAÇÃO: Verifica se a localização está bloqueada pelo admin (clientes presenciais)
    end_date = @outdoor.selected_start_date + @outdoor.selected_quantity_month.months
    if @outdoor.outdoor_location.present? &&
       LocationBlockedDate.location_blocked_for_period?(@outdoor.outdoor_location, @outdoor.selected_start_date, end_date)
      next_available = LocationBlockedDate.minimum_start_date_for_location(@outdoor.outdoor_location)
      redirect_to find_date_home_path, alert: "Este período não está disponível para a localização selecionada. " \
                                              "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. Por favor, altere a data."
      return
    end

    # ✅ SEGURANÇA: Calcula valor no BACKEND (não aceita do frontend)
    total_amount = BudgetCalculator.calculate_total(@outdoor)

    Rails.logger.info "🔒 Total calculado no backend: R$ #{total_amount}"
    Rails.logger.info "🔒 Outdoor pertence ao usuário: #{current_user.id}"

    # Salva os dados na session (NÃO cria rent ainda)
    session[:pending_checkout] = {
      outdoor_id: @outdoor.id,
      start_date: @outdoor.selected_start_date.to_s,
      end_date: (@outdoor.selected_start_date + @outdoor.selected_quantity_month.months).to_s,
      quantity_months: @outdoor.selected_quantity_month,
      total_amount: total_amount
    }

    redirect_to new_checkout_path
  end

  def redirect_whatsapp
    # 🔒 SEGURANÇA: Busca apenas nos rents do current_user
    @rent = current_user.rents.find_by(id: params[:id])

    unless @rent
      redirect_to root_path, alert: "Pedido não encontrado."
      return
    end

    # Corrigido: outdoor_type em vez de name (baseado nos seus params)
    mensagem = "Olá! Acabei de pagar o Outdoor #{@rent.outdoor.outdoor_type}. O ID do meu pedido é ##{@rent.id}."

    texto_url = URI.encode_www_form_component(mensagem)
    numero_whatsapp = "5546999776924" # Seu número

    link_wpp = "https://wa.me/#{numero_whatsapp}?text=#{texto_url}"

    redirect_to link_wpp, allow_other_host: true
  end

  private

  def set_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor
  end

  def outdoor_params
    params.permit(:outdoor_type, :outdoor_location, :outdoor_size)
  end

  # 🔒 Verifica se as datas salvas no outdoor estão bloqueadas por localização
  def outdoor_dates_blocked?(outdoor)
    return false unless outdoor&.outdoor_location.present? &&
                        outdoor&.selected_start_date.present? &&
                        outdoor&.selected_quantity_month.present? &&
                        outdoor.selected_quantity_month > 0

    end_date = outdoor.selected_start_date + outdoor.selected_quantity_month.months
    LocationBlockedDate.location_blocked_for_period?(outdoor.outdoor_location, outdoor.selected_start_date, end_date)
  end
end

