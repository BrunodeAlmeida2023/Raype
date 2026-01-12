class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end

  def show
    redirect_to root_path
  end

  def find_outdoor
  end

  def find_date
  end

  def choose_art
  end

  def post_find_outdoor
    outdoor_type = params[:outdoor_type]
    location = params[:location]

    # Aqui você pode processar os dados, salvar no banco, enviar email, etc.
    flash[:notice] = "Outdoor #{outdoor_type} selecionado para #{location}"
    redirect_to root_path
  end

  def post_find_date
    selected_date = params[:selected_date]

    # Aqui você pode processar a data selecionada
    flash[:notice] = "Data selecionada: #{selected_date}"
    redirect_to root_path
  end

  def post_choose_art
    art_file = params[:art_file]
    art_description = params[:art_description]

    # Aqui você pode processar o upload da arte
    if art_file.present?
      flash[:notice] = "Arte enviada com sucesso!"
    else
      flash[:alert] = "Por favor, selecione uma imagem"
    end

    redirect_to root_path
  end
end

