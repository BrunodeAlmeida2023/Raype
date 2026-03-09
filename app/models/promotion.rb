class Promotion < ApplicationRecord
  # Relacionamentos
  belongs_to :admin_user, class_name: 'User', foreign_key: 'created_by', optional: true

  # Enums para outdoor_location (deve coincidir com Outdoor model)
  enum outdoor_location: {
    outdoor_01: 0,
    outdoor_02: 1,
    outdoor_03: 2
  }

  # Enum para tipo de promoção
  enum promotion_type: {
    monthly: 0,        # Promoção na mensalidade
    installation: 1    # Promoção na instalação
  }

  # Validações
  validates :outdoor_location, presence: true
  validates :promotion_type, presence: true
  validates :original_price, presence: true, numericality: { greater_than: 0 }
  validates :promotional_price, presence: true, numericality: { greater_than: 0 }
  validate :promotional_price_less_than_original
  validate :end_date_after_start_date

  # Scopes
  scope :active_promotions, -> { where(active: true) }
  scope :current, -> {
    where(active: true)
      .where('start_date <= ? AND (end_date >= ? OR end_date IS NULL)', Date.today, Date.today)
  }
  scope :for_location, ->(location) { where(outdoor_location: location) }
  scope :for_type, ->(type) { where(promotion_type: type) }

  # Métodos de classe
  def self.current_promotion_for(location, type)
    current
      .for_location(location)
      .for_type(type)
      .order(created_at: :desc)
      .first
  end

  # Retorna o desconto em porcentagem
  def discount_percentage
    return 0 if original_price.zero?
    ((original_price - promotional_price) / original_price * 100).round(2)
  end

  # Verifica se a promoção está ativa no momento
  def active_now?
    return false unless active
    return false if start_date && start_date > Date.today
    return false if end_date && end_date < Date.today
    true
  end

  # Label amigável da localização
  def outdoor_location_label
    Outdoor.outdoor_location_options.find { |opt| opt[1] == outdoor_location }&.first || outdoor_location
  end

  # Label amigável do tipo
  def promotion_type_label
    case promotion_type
    when 'monthly'
      'Mensalidade'
    when 'installation'
      'Instalação'
    else
      promotion_type.titleize
    end
  end

  private

  def promotional_price_less_than_original
    return if promotional_price.blank? || original_price.blank?

    if promotional_price >= original_price
      errors.add(:promotional_price, 'deve ser menor que o preço original')
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'deve ser posterior à data inicial')
    end
  end
end
