module CheckoutHelper
  # Formata o valor total com moeda brasileira
  def format_checkout_currency(amount)
    "R$ #{number_with_delimiter(amount.to_i, delimiter: '.')},00"
  end

  # Formata o valor com precisão para parcelas
  def format_installment_value(amount)
    "R$ #{number_with_precision(amount, precision: 2, delimiter: '.', separator: ',')}"
  end

  # Retorna o texto do período formatado
  def format_checkout_period(start_date, end_date)
    "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
  end

  # Pluraliza meses
  def pluralize_checkout_months(count)
    count == 1 ? 'mês' : 'meses'
  end

  # Pluraliza artes
  def pluralize_checkout_arts(count)
    count == 1 ? 'arte' : 'artes'
  end

  # Classe CSS do badge de acordo com o método de pagamento
  def payment_method_badge_class(method)
    case method.to_s.downcase
    when 'pix', 'boleto'
      'instant-badge'
    when 'credit_card', 'debit_card', 'card'
      'credit-badge'
    else
      'default-badge'
    end
  end

  # Ícone do método de pagamento
  def payment_method_icon(method)
    case method.to_s.downcase
    when 'pix'
      'fas fa-qrcode'
    when 'boleto'
      'fas fa-barcode'
    when 'credit_card', 'card'
      'fas fa-credit-card'
    when 'debit_card'
      'fas fa-money-check'
    else
      'fas fa-money-bill'
    end
  end

  # Calcula o valor de cada parcela
  def calculate_installment_value(total, installments)
    (total.to_f / installments.to_i).round(2)
  end

  # Link do WhatsApp formatado para pedido
  def pedido_whatsapp_link(rent)
    message = "Olá! Acabei de realizar o pagamento do meu outdoor (Pedido ##{rent.id}). Gostaria de enviar as informações para impressão."
    "https://wa.me/5546999776924?text=#{URI.encode_www_form_component(message)}"
  end

  # Verifica se o usuário tem permissão para visualizar o pedido
  def can_view_order?(rent, user)
    rent.user_id == user.id || user.admin?
  end
end

