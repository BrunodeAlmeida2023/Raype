module Admin
  class RentsController < BaseController
    def index
      add_breadcrumb('Aluguéis')

      @rents = Rent.includes(:user, :outdoor)
                  .order(created_at: :desc)

      # Filtros
      @rents = @rents.where(status: params[:status]) if params[:status].present?
    end

    def show
      @rent = Rent.includes(:user, :outdoor).find(params[:id])
      add_breadcrumb('Aluguéis', admin_rents_path)
      add_breadcrumb("Aluguel ##{@rent.id}")
    end

    def update
      @rent = Rent.find(params[:id])

      if @rent.update(rent_params)
        Rails.logger.info "📝 Admin #{current_user.email} atualizou Rent ##{@rent.id}: #{rent_params.inspect}"
        redirect_to admin_rent_path(@rent), notice: 'Aluguel atualizado com sucesso!'
      else
        render :show
      end
    end

    private

    def rent_params
      params.require(:rent).permit(:status, :payment_method)
    end
  end
end


