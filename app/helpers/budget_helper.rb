module BudgetHelper
  def calculate_outdoor_base_price(outdoor)
    return 0 unless outdoor&.outdoor_type.present?

    # Preços base por tipo de outdoor
    case outdoor.outdoor_type.downcase
    when 'padrão'
      2500
    when 'premium'
      4000
    when 'digital'
      6000
    else
      2000
    end
  end

  def calculate_monthly_price(outdoor)
    calculate_outdoor_base_price(outdoor)
  end

  def calculate_art_price(outdoor)
    return 0 unless outdoor&.art_quantity.present?

    art_count = outdoor.art_quantity.to_i
    return 0 if art_count <= 0

    # Preço por arte
    price_per_art = 350
    art_count * price_per_art
  end

  def calculate_installation_fee
    # Taxa de instalação fixa
    1200
  end

  def calculate_design_fee(outdoor)
    return 0 unless outdoor&.art_quantity.present? && outdoor.art_quantity > 0

    # Taxa de design se tem artes
    800
  end

  def calculate_total_budget(outdoor)
    return 0 unless outdoor

    months = outdoor.selected_quantity_month.to_i
    return 0 if months <= 0

    monthly_price = calculate_monthly_price(outdoor)
    art_price = calculate_art_price(outdoor)
    installation_fee = calculate_installation_fee
    design_fee = calculate_design_fee(outdoor)

    subtotal = (monthly_price * months) + art_price + installation_fee + design_fee

    # Aplicar desconto se tiver (futuro)
    subtotal
  end

  def format_budget_currency(amount)
    "R$ #{number_with_delimiter(amount.to_i, delimiter: '.')},00"
  end

  def budget_breakdown(outdoor)
    return {} unless outdoor

    months = outdoor.selected_quantity_month.to_i
    monthly_price = calculate_monthly_price(outdoor)

    {
      monthly_price: monthly_price,
      months: months,
      rental_total: monthly_price * months,
      art_price: calculate_art_price(outdoor),
      installation_fee: calculate_installation_fee,
      design_fee: calculate_design_fee(outdoor),
      total: calculate_total_budget(outdoor)
    }
  end
end

