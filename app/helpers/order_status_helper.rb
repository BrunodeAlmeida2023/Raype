module OrderStatusHelper
  def order_status_badge_class(status)
    case status
    when 'paid'
      'paid'
    when 'pending'
      'pending'
    when 'canceled'
      'canceled'
    else
      'default'
    end
  end

  def order_status_icon(status)
    case status
    when 'paid'
      'fas fa-check-circle'
    when 'pending'
      'fas fa-clock'
    when 'canceled'
      'fas fa-times-circle'
    else
      'fas fa-info-circle'
    end
  end

  def order_status_text(status)
    case status
    when 'paid'
      'Pagamento Confirmado'
    when 'pending'
      'Aguardando Pagamento'
    when 'canceled'
      'Cancelado'
    else
      status.titleize
    end
  end

  def format_currency(amount)
    "R$ #{number_with_delimiter(amount.to_i, delimiter: '.')},00"
  end

  def format_date_range(start_date, end_date)
    "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
  end
end

