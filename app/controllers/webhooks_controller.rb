class WebhooksController < ApplicationController
  # IMPORTANTE: O Asaas não envia o token CSRF do Rails
  skip_before_action :verify_authenticity_token, only: [:asaas]

  def asaas
    # Log de recebimento
    Rails.logger.info "=" * 80
    Rails.logger.info "🔔 WEBHOOK ASAAS RECEBIDO"
    Rails.logger.info "=" * 80

    event = params[:event]
    Rails.logger.info "📩 Evento: #{event}"
    Rails.logger.info "📩 Payload completo: #{params.to_json}"

    # Eventos que confirmam pagamento
    if event == 'PAYMENT_RECEIVED' || event == 'PAYMENT_CONFIRMED'
      # Tenta pegar o externalReference (ID do rent)
      external_reference = params.dig(:payment, :externalReference)
      asaas_payment_id = params.dig(:payment, :id)
      billing_type = params.dig(:payment, :billingType) # Método REAL usado pelo usuário

      Rails.logger.info "🔍 External Reference recebido: #{external_reference}"
      Rails.logger.info "🔍 Asaas Payment ID: #{asaas_payment_id}"
      Rails.logger.info "🔍 Billing Type (método real): #{billing_type}"

      # Busca o rent pelo ID (que foi usado como externalReference)
      rent = if external_reference.present?
               Rails.logger.info "🔍 Tentando encontrar Rent com ID: #{external_reference}"
               # Tenta primeiro pelo ID direto
               found = Rent.find_by(id: external_reference)

               if found.nil?
                 # Se não encontrar, tenta buscar por externalReference que pode ser "rent_id_parc_1" (carnê)
                 base_id = external_reference.to_s.split('_').first
                 Rails.logger.info "🔍 Não encontrou direto, tentando com base_id: #{base_id}"
                 found = Rent.find_by("id = ?", base_id)
               end

               found
             else
               # Fallback: tenta buscar pelo asaas_id se já foi salvo antes
               Rails.logger.info "🔍 External Reference vazio, tentando por asaas_id: #{asaas_payment_id}"
               Rent.find_by(asaas_id: asaas_payment_id)
             end

      if rent
        Rails.logger.info "✅ Rent ##{rent.id} ENCONTRADO!"
        Rails.logger.info "   Status ANTES: #{rent.status}"
        Rails.logger.info "   Payment Method ANTES: #{rent.payment_method}"

        # Converte billingType do Asaas para formato legível
        payment_method_readable = case billing_type
                                  when 'CREDIT_CARD' then 'Cartão de Crédito'
                                  when 'DEBIT_CARD' then 'Cartão de Débito'
                                  when 'PIX' then 'PIX'
                                  when 'BOLETO' then 'Boleto Bancário'
                                  else billing_type
                                  end

        # Atualiza o aluguel para PAGO com o método REAL usado
        if rent.update(status: 'paid', asaas_id: asaas_payment_id, payment_method: payment_method_readable)
          Rails.logger.info "✅ Rent ##{rent.id} ATUALIZADO PARA PAGO!"
          Rails.logger.info "   Status DEPOIS: #{rent.reload.status}"
          Rails.logger.info "   Payment Method DEPOIS: #{rent.payment_method}"
          Rails.logger.info "   Asaas ID salvo: #{rent.asaas_id}"
        else
          Rails.logger.error "❌ ERRO ao atualizar Rent ##{rent.id}: #{rent.errors.full_messages.join(', ')}"
        end

        Rails.logger.info "=" * 80
        head :ok
      else
        Rails.logger.error "❌ RENT NÃO ENCONTRADO!"
        Rails.logger.error "   External Reference: #{external_reference}"
        Rails.logger.error "   Asaas Payment ID: #{asaas_payment_id}"
        Rails.logger.error "   Rents existentes: #{Rent.pluck(:id).join(', ')}"
        Rails.logger.info "=" * 80
        head :not_found
      end
    else
      Rails.logger.info "ℹ️ Evento ignorado (não é pagamento): #{event}"
      Rails.logger.info "=" * 80
      head :ok
    end
  rescue StandardError => e
    Rails.logger.error "💥 ERRO NO WEBHOOK: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    Rails.logger.info "=" * 80
    head :internal_server_error
  end
end
