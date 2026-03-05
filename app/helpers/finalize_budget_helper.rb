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

  # Formata o valor com delimitador
  def format_budget_value(amount)
    number_with_delimiter(amount.to_i, delimiter: '.')
  end

  # Retorna os dados do orçamento de forma segura
  def safe_budget_data(outdoor)
    return {} unless outdoor

    budget = BudgetCalculator.breakdown(outdoor)

    {
      outdoor_type: outdoor.outdoor_type_label,
      outdoor_size: outdoor.outdoor_size_label,
      outdoor_location: outdoor.outdoor_location_label,
      start_date: outdoor.selected_start_date,
      end_date: outdoor.selected_end_date,
      months: budget[:months],
      art_quantity: outdoor.has_own_art ? outdoor.total_arts_count : 0,
      custom_art_quantity: outdoor.has_own_art ? 0 : outdoor.total_arts_count,
      selected_faces: outdoor.selected_faces || [],
      budget: budget
    }
  end
end

