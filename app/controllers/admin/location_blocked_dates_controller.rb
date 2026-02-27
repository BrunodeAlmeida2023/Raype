module Admin
  class LocationBlockedDatesController < BaseController
    before_action :set_location_blocked_date, only: [:destroy]

    def index
      add_breadcrumb('Bloqueios por Localização')

      @location_blocked_dates = LocationBlockedDate.includes(:admin_user)
                                                    .order(start_date: :desc)
    end

    def new
      add_breadcrumb('Bloqueios por Localização', admin_location_blocked_dates_path)
      add_breadcrumb('Novo Bloqueio de Localização')

      @location_blocked_date = LocationBlockedDate.new
    end

    def create
      @location_blocked_date = LocationBlockedDate.new(location_blocked_date_params)
      @location_blocked_date.blocked_by = current_user.id

      if @location_blocked_date.save
        location_label = @location_blocked_date.location_label
        Rails.logger.info "🔒 Admin #{current_user.email} bloqueou localização '#{location_label}': #{@location_blocked_date.start_date} a #{@location_blocked_date.end_date}"

        # Conta os rents cancelados automaticamente pelo callback after_create
        canceled_count = @location_blocked_date.overlapping_pending_rents.count # Já foram cancelados pelo callback

        notice_msg = "✅ Localização bloqueada com sucesso! Usuários não poderão selecionar esta localização no período especificado."

        # Verifica rents pagos que conflitam (apenas aviso, não cancela)
        if conflicting_paid_rent?
          flash[:alert] = "⚠️ Atenção: Já existe(m) aluguel(is) PAGO(S) nesta localização e período. Verifique manualmente."
        end

        redirect_to admin_location_blocked_dates_path, notice: notice_msg
      else
        add_breadcrumb('Bloqueios por Localização', admin_location_blocked_dates_path)
        add_breadcrumb('Novo Bloqueio de Localização')
        render :new
      end
    end

    def destroy
      location_label = @location_blocked_date.location_label
      if @location_blocked_date.destroy
        Rails.logger.info "🔓 Admin #{current_user.email} desbloqueou localização '#{location_label}'"
        redirect_to admin_location_blocked_dates_path, notice: '✅ Bloqueio de localização removido com sucesso!'
      else
        redirect_to admin_location_blocked_dates_path, alert: '❌ Erro ao remover bloqueio.'
      end
    end

    private

    def set_location_blocked_date
      @location_blocked_date = LocationBlockedDate.find(params[:id])
    end

    def location_blocked_date_params
      params.require(:location_blocked_date).permit(:outdoor_location, :start_date, :end_date, :reason)
    end

    def conflicting_paid_rent?
      # Busca rents PAGOS que usam outdoors nesta localização e período
      Rent.joins(:outdoor)
          .where(outdoors: { outdoor_location: @location_blocked_date.outdoor_location }, status: 'paid')
          .where('(rents.start_date <= ? AND rents.end_date >= ?) OR (rents.start_date <= ? AND rents.end_date >= ?) OR (rents.start_date >= ? AND rents.end_date <= ?)',
                 @location_blocked_date.start_date, @location_blocked_date.start_date,
                 @location_blocked_date.end_date, @location_blocked_date.end_date,
                 @location_blocked_date.start_date, @location_blocked_date.end_date)
          .exists?
    end
  end
end

