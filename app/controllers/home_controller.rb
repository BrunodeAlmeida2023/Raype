class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :set_outdoor, only: [:find_outdoor, :find_date, :choose_art]

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
    end_date = params[:selected_end_date]

    # Validação no backend: data final deve ser no mínimo 1 mês após a data inicial
    if start_date.present? && end_date.present?
      start = Date.parse(start_date)
      end_d = Date.parse(end_date)
      min_end_date = start + 1.month

      if end_d < min_end_date
        flash[:alert] = "A data final deve ser no mínimo 1 mês após a data inicial."
        redirect_to find_date_home_path
        return
      end
    end

    if @outdoor.update(selected_start_date: start_date, selected_end_date: end_date)
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

  private

  def set_outdoor
    @outdoor = current_user.outdoor || current_user.build_outdoor
  end

  def outdoor_params
    params.permit(:outdoor_type, :outdoor_location, :outdoor_size)
  end
end

