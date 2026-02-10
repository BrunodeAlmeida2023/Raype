class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:asaas]

  def asaas
    event = params[:event]

    Rails.logger.info "📩 Webhook Asaas recebido: #{event}"

    if event == 'PAYMENT_RECEIVED' || event == 'PAYMENT_CONFIRMED'
      rent_id = params[:payment][:externalReference]

      # Busca o ALUGUEL
      rent = Rent.find_by(id: rent_id)

      if rent
        # Atualiza o aluguel para PAGO
        rent.update(status: 'paid', asaas_id: params[:payment][:id])
        Rails.logger.info "✅ Aluguel ##{rent.id} confirmado!"
        head :ok
      else
        Rails.logger.error "❌ Aluguel ##{rent_id} não encontrado"
        head :not_found
      end
    else
      Rails.logger.info "ℹ️ Evento ignorado: #{event}"
      head :ok
    end
  end
end
