module BudgetHelper
  def calculate_outdoor_base_price(outdoor)
    BudgetCalculator.monthly_price_for_type(outdoor&.outdoor_type)
  end

  def calculate_monthly_price(outdoor)
    BudgetCalculator.monthly_price_for_type(outdoor&.outdoor_type)
  end

  def calculate_art_price(outdoor)
    BudgetCalculator.calculate_art_cost(outdoor)
  end

  def calculate_installation_fee(outdoor)
    months = BudgetCalculator.calculate_months_from_dates(outdoor)
    (months < 2) ? BudgetCalculator::INSTALLATION_FEE : 0
  end

  def calculate_total_budget(outdoor)
    BudgetCalculator.calculate_total(outdoor)
  end

  def format_budget_currency(amount)
    "R$ #{number_with_delimiter(amount.to_i, delimiter: '.')},00"
  end

  def budget_breakdown(outdoor)
    BudgetCalculator.breakdown(outdoor)
  end
end

