module Admin
  class LocationBlockedFacesController < BaseController
    before_action :set_location_blocked_face, only: [:edit, :update, :destroy]

    def index
      add_breadcrumb('Bloqueios de Faces por Localização')

      @location_blocked_faces = LocationBlockedFace.includes(:admin_user)
                                                    .order(start_date: :desc)
    end

    def new
      add_breadcrumb('Bloqueios de Faces', admin_location_blocked_faces_path)
      add_breadcrumb('Novo Bloqueio de Faces')

      @location_blocked_face = LocationBlockedFace.new
    end

    def create
      @location_blocked_face = LocationBlockedFace.new(location_blocked_face_params)
      @location_blocked_face.blocked_by = current_user.id

      # Converte os parâmetros de faces para array de inteiros
      if params[:location_blocked_face][:blocked_faces].present?
        faces = params[:location_blocked_face][:blocked_faces].reject(&:blank?).map(&:to_i)
        @location_blocked_face.blocked_faces = faces
      end

      if @location_blocked_face.save
        location_label = Outdoor.outdoor_location_options.find { |opt| opt[1] == @location_blocked_face.outdoor_location }&.first
        faces_text = @location_blocked_face.blocked_faces.join(', ')

        Rails.logger.info "🔒 Admin #{current_user.email} bloqueou face(s) #{faces_text} da localização '#{location_label}': #{@location_blocked_face.start_date} a #{@location_blocked_face.end_date}"

        notice_msg = "✅ Face(s) bloqueada(s) com sucesso! Usuários não poderão selecionar estas faces no período especificado."

        # Verifica rents que conflitam com as faces bloqueadas
        if conflicting_rents?
          flash[:alert] = "⚠️ Atenção: Já existe(m) aluguel(is) com estas faces nesta localização e período. Verifique manualmente."
        end

        redirect_to admin_location_blocked_faces_path, notice: notice_msg
      else
        add_breadcrumb('Bloqueios de Faces', admin_location_blocked_faces_path)
        add_breadcrumb('Novo Bloqueio de Faces')
        render :new
      end
    end

    def edit
      add_breadcrumb('Bloqueios de Faces', admin_location_blocked_faces_path)
      add_breadcrumb('Editar Bloqueio de Faces')
    end

    def update
      # Converte os parâmetros de faces para array de inteiros
      if params[:location_blocked_face][:blocked_faces].present?
        faces = params[:location_blocked_face][:blocked_faces].reject(&:blank?).map(&:to_i)
        @location_blocked_face.blocked_faces = faces
      end

      if @location_blocked_face.update(location_blocked_face_params.except(:blocked_faces))
        redirect_to admin_location_blocked_faces_path, notice: '✅ Bloqueio de faces atualizado com sucesso!'
      else
        add_breadcrumb('Bloqueios de Faces', admin_location_blocked_faces_path)
        add_breadcrumb('Editar Bloqueio de Faces')
        render :edit
      end
    end

    def destroy
      location_label = Outdoor.outdoor_location_options.find { |opt| opt[1] == @location_blocked_face.outdoor_location }&.first
      faces_text = @location_blocked_face.blocked_faces.join(', ')

      if @location_blocked_face.destroy
        Rails.logger.info "🔓 Admin #{current_user.email} desbloqueou face(s) #{faces_text} da localização '#{location_label}'"
        redirect_to admin_location_blocked_faces_path, notice: '✅ Bloqueio de faces removido com sucesso!'
      else
        redirect_to admin_location_blocked_faces_path, alert: '❌ Erro ao remover bloqueio.'
      end
    end

    private

    def set_location_blocked_face
      @location_blocked_face = LocationBlockedFace.find(params[:id])
    end

    def location_blocked_face_params
      params.require(:location_blocked_face).permit(:outdoor_location, :start_date, :end_date, :reason)
    end

    def conflicting_rents?
      # Busca outdoors nesta localização no período especificado
      conflicting_outdoors = Outdoor.where(outdoor_location: @location_blocked_face.outdoor_location)
                                    .where('selected_start_date <= ? AND selected_end_date >= ?',
                                           @location_blocked_face.end_date,
                                           @location_blocked_face.start_date)

      # Verifica se algum outdoor tem faces que conflitam
      conflicting_outdoors.any? do |outdoor|
        outdoor_faces = outdoor.selected_faces || []
        blocked_faces = @location_blocked_face.blocked_faces || []
        (outdoor_faces & blocked_faces).any? # Há interseção?
      end
    end
  end
end

