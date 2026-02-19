# Budget Calculator - Serviço para cálculo de orçamentos
# Centraliza toda lógica de cálculo para evitar manipulação no frontend
class BudgetCalculator
  # Tabela de preços (poderia vir de uma tabela Price no banco)
  MONTHLY_PRICES = {
    'padrão' => 1200,
    'premium' => 2000,
    'digital' => 3500
  }.freeze

  PRICE_PER_ART = 600
  INSTALLATION_FEE = 1200
  DESIGN_FEE = 800

  class << self
    # Calcula o valor total do orçamento
    def calculate_total(outdoor)
      return 0 unless outdoor

      monthly_rental = calculate_rental_cost(outdoor)
      art_cost = calculate_art_cost(outdoor)
      installation = INSTALLATION_FEE
      design = outdoor.art_quantity.to_i > 0 ? DESIGN_FEE : 0

      total = monthly_rental + art_cost + installation + design

      Rails.logger.info "📊 Breakdown: Rental=#{monthly_rental}, Art=#{art_cost}, Install=#{installation}, Design=#{design}, Total=#{total}"

      total
    end

    # Calcula custo do aluguel mensal
    def calculate_rental_cost(outdoor)
      months = outdoor.selected_quantity_month.to_i
      return 0 if months <= 0

      price_per_month = monthly_price_for_type(outdoor.outdoor_type)
      price_per_month * months
    end

    # Calcula custo das artes
    def calculate_art_cost(outdoor)
      art_count = outdoor.art_quantity.to_i
      return 0 if art_count <= 0

      art_count * PRICE_PER_ART
    end

    # Retorna preço mensal baseado no tipo de outdoor
    def monthly_price_for_type(outdoor_type)
      type_key = outdoor_type.to_s.downcase
      MONTHLY_PRICES[type_key] || MONTHLY_PRICES['padrão']
    end

    # Retorna breakdown detalhado para exibição
    def breakdown(outdoor)
      return {} unless outdoor

      months = outdoor.selected_quantity_month.to_i
      art_count = outdoor.art_quantity.to_i
      monthly_price = monthly_price_for_type(outdoor.outdoor_type)

      {
        monthly_price: monthly_price,
        months: months,
        rental_total: monthly_price * months,
        art_price_per_unit: PRICE_PER_ART,
        art_count: art_count,
        art_total: calculate_art_cost(outdoor),
        installation_fee: INSTALLATION_FEE,
        design_fee: art_count > 0 ? DESIGN_FEE : 0,
        total: calculate_total(outdoor)
      }
    end
  end
end

