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

  # app/controllers/home_controller.rb

  def post_finalize_budget
    @outdoor = Outdoor.find(params[:outdoor_id])

    # 1. Tratamento do valor (tira R$ se tiver e converte)
    valor_total = params[:total_amount].to_s.gsub('R$', '').gsub(',', '.').to_f - 7795

    # 2. Cria o Aluguel
    @rent = Rent.new(
      user: current_user,
      outdoor: @outdoor,
      start_date: @outdoor.selected_start_date,
      end_date: @outdoor.selected_start_date + @outdoor.selected_quantity_month.months,
      total_amount: valor_total,
      status: 'pending'
    )

    if @rent.save
      # 3. Prepara a URL de Retorno (Para onde o Asaas manda o cliente depois de pagar)
      # Isso gera o link: seite.com/pedido/whatsapp/123
      url_retorno_whatsapp = pedido_whatsapp_url(@rent.id, host: request.base_url)

      # 4. Chama o Service com os 5 Argumentos
      asaas = AsaasService.new

      link_pagamento = asaas.create_payment_url(
        current_user, # 1. Usuário
        valor_total, # 2. Valor
        "Aluguel Outdoor: #{@outdoor.outdoor_type}", # 3. Descrição
        @rent.id, # 4. ID Externo (para Webhook)
        url_retorno_whatsapp # 5. URL de Redirecionamento (NOVO)
      )

      if link_pagamento
        # SUCESSO: Cliente vai para o Asaas
        redirect_to link_pagamento, allow_other_host: true
      else
        # FALHA: Apaga o rent e avisa
        @rent.destroy
        redirect_to root_path, alert: "Erro de comunicação com o Asaas. Tente novamente."
      end

    else
      redirect_to root_path, alert: "Erro ao criar pedido: #{@rent.errors.full_messages.join(', ')}"
    end
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

