module Admin
  class PromotionsController < BaseController
    before_action :set_promotion, only: [:edit, :update, :destroy, :toggle_active]

    def index
      add_breadcrumb('Promoções')
      @promotions = Promotion.includes(:admin_user).order(created_at: :desc)
    end

    def new
      add_breadcrumb('Promoções', admin_promotions_path)
      add_breadcrumb('Nova Promoção')
      @promotion = Promotion.new
    end

    def create
      @promotion = Promotion.new(promotion_params)
      @promotion.created_by = current_user.id

      if @promotion.save
        location_label = @promotion.outdoor_location_label
        type_label = @promotion.promotion_type_label

        Rails.logger.info "🎉 Admin #{current_user.email} criou promoção de #{type_label} para '#{location_label}': R$ #{@promotion.original_price} → R$ #{@promotion.promotional_price}"
        redirect_to admin_promotions_path, notice: '✅ Promoção criada com sucesso!'
      else
        add_breadcrumb('Promoções', admin_promotions_path)
        add_breadcrumb('Nova Promoção')
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      add_breadcrumb('Promoções', admin_promotions_path)
      add_breadcrumb('Editar Promoção')
    end

    def update
      if @promotion.update(promotion_params)
        location_label = @promotion.outdoor_location_label
        type_label = @promotion.promotion_type_label

        Rails.logger.info "✏️ Admin #{current_user.email} atualizou promoção de #{type_label} para '#{location_label}'"
        redirect_to admin_promotions_path, notice: '✅ Promoção atualizada com sucesso!'
      else
        add_breadcrumb('Promoções', admin_promotions_path)
        add_breadcrumb('Editar Promoção')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      location_label = @promotion.outdoor_location_label
      type_label = @promotion.promotion_type_label

      if @promotion.destroy
        Rails.logger.info "🗑️ Admin #{current_user.email} removeu promoção de #{type_label} para '#{location_label}'"
        redirect_to admin_promotions_path, notice: '✅ Promoção removida com sucesso!'
      else
        redirect_to admin_promotions_path, alert: '❌ Erro ao remover promoção.'
      end
    end

    def toggle_active
      @promotion.update!(active: !@promotion.active)
      status_text = @promotion.active? ? 'ativada' : 'desativada'

      Rails.logger.info "🔄 Admin #{current_user.email} #{status_text} promoção ##{@promotion.id}"
      redirect_to admin_promotions_path, notice: "✅ Promoção #{status_text} com sucesso!"
    end

    private

    def set_promotion
      @promotion = Promotion.find(params[:id])
    end

    def promotion_params
      params.require(:promotion).permit(
        :outdoor_location,
        :promotion_type,
        :original_price,
        :promotional_price,
        :active,
        :start_date,
        :end_date,
        :description
      )
    end
  end
end

