module FinalizeBudgetHelper
  def format_budget_date(date)
    return 'N/A' unless date
    date.strftime('%d/%m/%Y')
  end

  def pluralize_months(count)
    count == 1 ? 'mês' : 'meses'
  end

  def pluralize_arts(count)
    count == 1 ? 'arte' : 'artes'
  end

  def budget_item_label(type, count = nil)
    case type
    when :rental
      "Aluguel (#{count} #{pluralize_months(count)})"
    when :arts
      "Artes (#{count} #{pluralize_arts(count)})"
    when :installation
      "Instalação"
    when :design
      "Design"
    end
  end

  # Calcula a data final baseada na data inicial e quantidade de meses
  def calculate_end_date(outdoor)
    return nil unless outdoor&.selected_start_date&.present? && outdoor&.selected_quantity_month&.present?
    outdoor.selected_start_date + outdoor.selected_quantity_month.months
  end

  # Formata o valor com delimitador
  def format_budget_value(amount)
    number_with_delimiter(amount.to_i, delimiter: '.')
  end

  # Retorna os dados do orçamento de forma segura
  def safe_budget_data(outdoor)
    return {} unless outdoor

    budget = BudgetCalculator.breakdown(outdoor)
    end_date = calculate_end_date(outdoor)

    {
      outdoor_type: outdoor.outdoor_type&.titleize,
      outdoor_size: outdoor.outdoor_size,
      outdoor_location: outdoor.outdoor_location,
      start_date: outdoor.selected_start_date,
      end_date: end_date,
      months: budget[:months],
      art_quantity: outdoor.art_quantity || 0,
      budget: budget
    }
  end
end

