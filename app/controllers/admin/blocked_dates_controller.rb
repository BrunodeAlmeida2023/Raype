module Admin
  class BlockedDatesController < BaseController
    before_action :set_outdoor
    before_action :set_blocked_date, only: [:destroy]

    def index
      add_breadcrumb('Outdoors', admin_outdoors_path)
      add_breadcrumb("Outdoor ##{@outdoor.id}", admin_outdoor_path(@outdoor))
      add_breadcrumb('Datas Bloqueadas')

      @blocked_dates = @outdoor.blocked_dates.order(start_date: :desc)
    end

    def new
      add_breadcrumb('Outdoors', admin_outdoors_path)
      add_breadcrumb("Outdoor ##{@outdoor.id}", admin_outdoor_path(@outdoor))
      add_breadcrumb('Nova Data Bloqueada')

      @blocked_date = @outdoor.blocked_dates.build
    end

    def create
      @blocked_date = @outdoor.blocked_dates.build(blocked_date_params)
      @blocked_date.blocked_by = current_user.id

      # Verifica se já existe algum rent nesse período
      if conflicting_rent?
        flash.now[:alert] = "Já existe um aluguel confirmado neste período. Verifique antes de bloquear."
      end

      if @blocked_date.save
        Rails.logger.info "🔒 Admin #{current_user.email} bloqueou datas do Outdoor ##{@outdoor.id}: #{@blocked_date.start_date} a #{@blocked_date.end_date}"
        redirect_to admin_outdoor_path(@outdoor), notice: 'Período bloqueado com sucesso!'
      else
        add_breadcrumb('Outdoors', admin_outdoors_path)
        add_breadcrumb("Outdoor ##{@outdoor.id}", admin_outdoor_path(@outdoor))
        add_breadcrumb('Nova Data Bloqueada')
        render :new
      end
    end

    def destroy
      if @blocked_date.destroy
        Rails.logger.info "🔓 Admin #{current_user.email} desbloqueou datas do Outdoor ##{@outdoor.id}"
        redirect_to admin_outdoor_path(@outdoor), notice: 'Bloqueio removido com sucesso!'
      else
        redirect_to admin_outdoor_path(@outdoor), alert: 'Erro ao remover bloqueio.'
      end
    end

    private

    def set_outdoor
      @outdoor = Outdoor.find(params[:outdoor_id])
    end

    def set_blocked_date
      @blocked_date = @outdoor.blocked_dates.find(params[:id])
    end

    def blocked_date_params
      params.require(:outdoor_blocked_date).permit(:start_date, :end_date, :reason)
    end

    def conflicting_rent?
      Rent.where(outdoor_id: @outdoor.id, status: 'paid')
          .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
                 @blocked_date.start_date, @blocked_date.start_date,
                 @blocked_date.end_date, @blocked_date.end_date,
                 @blocked_date.start_date, @blocked_date.end_date)
          .exists?
    end
  end
end

