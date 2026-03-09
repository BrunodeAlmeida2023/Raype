# Budget Calculator - Serviço para cálculo de orçamentos
# Centraliza toda lógica de cálculo para evitar manipulação no frontend
class BudgetCalculator
  # Tabela de preços (poderia vir de uma tabela Price no banco)
  MONTHLY_PRICES = {
    'padrão' => 600
  }.freeze

  PRICE_PER_ART = 975
  INSTALLATION_FEE = 1000 # Cobrado apenas para períodos menores que 2 meses

  class << self
    # Calcula o valor total do orçamento
    def calculate_total(outdoor)
      return 0 unless outdoor

      months = calculate_months_from_dates(outdoor)

      # Busca promoções ativas
      monthly_promotion = Promotion.current_promotion_for(outdoor.outdoor_location, :monthly)
      installation_promotion = Promotion.current_promotion_for(outdoor.outdoor_location, :installation)

      # Calcula mensalidade com promoção se existir
      monthly_price = monthly_promotion ? monthly_promotion.promotional_price : monthly_price_for_type(outdoor.outdoor_type)
      monthly_rental = monthly_price * months

      # Calcula instalação com promoção se existir
      installation = if months < 2
                       installation_promotion ? installation_promotion.promotional_price : INSTALLATION_FEE
                     else
                       0
                     end

      art_cost = calculate_art_cost(outdoor)
      total = monthly_rental + art_cost + installation

      Rails.logger.info "📊 Breakdown: Rental=#{monthly_rental}, Art=#{art_cost}, Install=#{installation}, Months=#{months}, Total=#{total}"

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

    # Calcula custo das artes (tanto próprias quanto criadas pela equipe)
    def calculate_art_cost(outdoor)
      return 0 unless outdoor && outdoor.total_arts_count > 0

      outdoor.total_arts_count * PRICE_PER_ART
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

      monthly_price = monthly_price_for_type(outdoor.outdoor_type)
      installation_fee = (months < 2) ? INSTALLATION_FEE : 0

      # Busca promoções ativas para esta localização
      monthly_promotion = Promotion.current_promotion_for(outdoor.outdoor_location, :monthly)
      installation_promotion = Promotion.current_promotion_for(outdoor.outdoor_location, :installation)

      # Aplica promoção na mensalidade se existir
      promotional_monthly_price = monthly_promotion ? monthly_promotion.promotional_price : nil
      final_monthly_price = promotional_monthly_price || monthly_price
      rental_total = final_monthly_price * months

      # Aplica promoção na instalação se existir
      promotional_installation_fee = installation_promotion ? installation_promotion.promotional_price : nil
      final_installation_fee = promotional_installation_fee || installation_fee

      # Recalcula o total com os valores promocionais
      total = rental_total + calculate_art_cost(outdoor) + final_installation_fee

      {
        monthly_price: monthly_price,
        promotional_monthly_price: promotional_monthly_price,
        has_monthly_promotion: monthly_promotion.present?,
        months: months,
        rental_total: rental_total,
        art_price_per_unit: PRICE_PER_ART,
        art_count: total_arts,
        art_total: calculate_art_cost(outdoor),
        installation_fee: installation_fee,
        promotional_installation_fee: promotional_installation_fee,
        has_installation_promotion: installation_promotion.present?,
        final_installation_fee: final_installation_fee,
        total: total
      }
    end
  end
end

