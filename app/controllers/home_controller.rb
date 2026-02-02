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
    # @outdoor já está setado pelo before_action
  end

  def find_date
    # @outdoor já está setado pelo before_action
  end

  def choose_art
    # @outdoor já está setado pelo before_action
  end

  def finalize_budget
    puts 'kakdakdakdakdakdkakdakodakodaokdaodokadokadokaok'
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

  def post_finalize_budget
    @outdoor = Outdoor.find(params[:outdoor_id])

    # 1. REMOVA OU COMENTE ESTA LINHA QUE CAUSA O ERRO
    # start_date = Date.parse(params[:selected_start_date])

    months = params[:selected_quantity_month].to_i

    # Se months vier vazio, force 1 mês ou trate o erro
    months = 1 if months.zero?
    
    unit_amount_cents = 60

    session = Stripe::Checkout::Session.create({
                                                 locale: 'pt-BR',
                                                 payment_method_types: ['card', 'boleto', 'pix'],
                                                 line_items: [{
                                                                price_data: {
                                                                  currency: 'brl',
                                                                  product_data: {
                                                                    name: "Locação Outdoor: #{@outdoor.outdoor_type}",
                                                                    # 2. SIMPLIFIQUE A DESCRIÇÃO (Tire a data daqui)
                                                                    description: "Período de locação: #{months} meses",
                                                                  },
                                                                  unit_amount: unit_amount_cents,
                                                                },
                                                                quantity: months,
                                                              }],
                                                 mode: 'payment',
                                                 success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
                                                 cancel_url: root_url,
                                                 metadata: {
                                                   outdoor_id: @outdoor.id,
                                                   user_id: current_user.id,
                                                   # 3. REMOVA A DATA DO METADATA TAMBÉM
                                                   # start_date: start_date.to_s,
                                                   months: months
                                                 }
                                               })

    redirect_to session.url, allow_other_host: true, status: 303
  end

  private

  def set_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor
  end

  def outdoor_params
    params.permit(:outdoor_type, :outdoor_location, :outdoor_size)
  end
end

