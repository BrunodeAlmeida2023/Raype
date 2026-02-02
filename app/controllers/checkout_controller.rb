class CheckoutController < ApplicationController
  class CheckoutController < ApplicationController
    def success
      # 1. Recupera a sessão do Stripe
      session = Stripe::Checkout::Session.retrieve(params[:session_id])

      # 2. Pega os dados que você escondeu no metadata
      outdoor_id = session.metadata.outdoor_id
      user_id = session.metadata.user_id
      start_date = session.metadata.start_date
      months = session.metadata.months

      # 3. (Opcional) Salva no seu banco de dados que o aluguel foi pago
      # Exemplo: Criar um registro na tabela 'Rent' ou 'Order'
      @rent = Rent.create!(
        outdoor_id: outdoor_id,
        user_id: user_id,
        start_date: start_date,
        end_date: Date.parse(start_date) + months.to_i.months,
        status: 'paid', # Importante: status pago!
        stripe_session_id: session.id,
        total_amount: session.amount_total / 100.0 # Convertendo de volta de centavos
      )

      @customer_name = session.customer_details.name
      flash[:notice] = "Pagamento confirmado com sucesso!"
    end
  end
end