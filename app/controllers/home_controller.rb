class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :set_outdoor, only: [:find_outdoor, :find_date, :choose_art, :finalize_budget]

  def index
    @user = current_user
    @outdoor = current_user.outdoor
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
      # Já existe um orçamento pago, redireciona para WhatsApp
      whatsapp_message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{paid_rent.id}). Gostaria de enviar as informações para impressão."
      whatsapp_url = "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(whatsapp_message)}"
      redirect_to whatsapp_url, allow_other_host: true, alert: "Você já possui um pedido pago. Entre em contato via WhatsApp para enviar suas informações."
      return
    end

    # Verifica se o usuário já possui um orçamento pendente
    existing_rent = current_user.rents.where(status: 'pending').first

    if existing_rent.present?
      # Já existe um orçamento pendente, redireciona para a página de status
      redirect_to order_status_path(existing_rent.id), alert: "Você já possui um orçamento pendente. Finalize ou cancele-o antes de criar um novo."
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

    # Salva a quantidade de artes
    @outdoor.art_quantity = params[:art_quantity].to_i if params[:art_quantity].present?

    # Anexa as artes se foram enviadas
    if params[:art_files].present?
      # Remove artes antigas antes de adicionar novas
      @outdoor.art_files.purge if @outdoor.art_files.attached?

      params[:art_files].each do |art_file|
        @outdoor.art_files.attach(art_file) if art_file.present?
      end
    end

    if @outdoor.save
      flash[:notice] = "Arte salva com sucesso!"
      redirect_to root_path
    else
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

    @outdoor = Outdoor.find(params[:outdoor_id])

    # ✅ SEGURANÇA: Calcula valor no BACKEND (não aceita do frontend)
    total_amount = BudgetCalculator.calculate_total(@outdoor)

    Rails.logger.info "🔒 Total calculado no backend: R$ #{total_amount}"

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
    @rent = Rent.find(params[:id])

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
end

