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
  CUSTOM_ART_FEE = 900 # Taxa por arte customizada criada pela equipe

  class << self
    # Calcula o valor total do orçamento
    def calculate_total(outdoor)
      return 0 unless outdoor

      monthly_rental = calculate_rental_cost(outdoor)
      art_cost = calculate_art_cost(outdoor)
      custom_art_cost = calculate_custom_art_cost(outdoor)
      installation = INSTALLATION_FEE
      # Cobra taxa de design se tiver selecionado faces (artes)
      has_arts = outdoor.total_arts_count > 0
      design = has_arts ? DESIGN_FEE : 0

      total = monthly_rental + art_cost + custom_art_cost + installation + design

      Rails.logger.info "📊 Breakdown: Rental=#{monthly_rental}, Art=#{art_cost}, CustomArt=#{custom_art_cost}, Install=#{installation}, Design=#{design}, Total=#{total}"

      total
    end

    # Calcula a quantidade de meses baseado nas datas selecionadas
    def calculate_months_from_dates(outdoor)
      return 0 unless outdoor&.selected_start_date.present? && outdoor&.selected_end_date.present?

      outdoor.duration_in_months
    end

    # Calcula custo do aluguel mensal
    def calculate_rental_cost(outdoor)
      months = calculate_months_from_dates(outdoor)
      return 0 if months <= 0

      price_per_month = monthly_price_for_type(outdoor.outdoor_type)
      price_per_month * months
    end

    # Calcula custo das artes (quando usuário tem arte própria)
    def calculate_art_cost(outdoor)
      return 0 unless outdoor&.has_own_art && outdoor.total_arts_count > 0

      outdoor.total_arts_count * PRICE_PER_ART
    end

    # Calcula custo de artes customizadas (criadas pela equipe)
    def calculate_custom_art_cost(outdoor)
      return 0 unless outdoor && !outdoor.has_own_art && outdoor.total_arts_count > 0

      outdoor.total_arts_count * CUSTOM_ART_FEE
    end

    # Retorna preço mensal baseado no tipo de outdoor
    def monthly_price_for_type(outdoor_type)
      type_key = outdoor_type.to_s.downcase
      MONTHLY_PRICES[type_key] || MONTHLY_PRICES['padrão']
    end

    # Retorna breakdown detalhado para exibição
    def breakdown(outdoor)
      return {} unless outdoor

      months = calculate_months_from_dates(outdoor)
      total_arts = outdoor.total_arts_count
      has_own_art = outdoor.has_own_art

      # Se tem arte própria, conta como art_count; caso contrário, como custom_art_count
      art_count = has_own_art ? total_arts : 0
      custom_art_count = has_own_art ? 0 : total_arts

      monthly_price = monthly_price_for_type(outdoor.outdoor_type)

      {
        monthly_price: monthly_price,
        months: months,
        rental_total: monthly_price * months,
        art_price_per_unit: PRICE_PER_ART,
        art_count: art_count,
        art_total: calculate_art_cost(outdoor),
        custom_art_price_per_unit: CUSTOM_ART_FEE,
        custom_art_count: custom_art_count,
        custom_art_total: calculate_custom_art_cost(outdoor),
        installation_fee: INSTALLATION_FEE,
        design_fee: (total_arts > 0) ? DESIGN_FEE : 0,
        total: calculate_total(outdoor)
      }
    end
  end
end

