class LocationBlockedDate < ApplicationRecord
  belongs_to :admin_user, class_name: 'User', foreign_key: 'blocked_by', optional: true

  # Enum para outdoor_location (mesmos valores do modelo Outdoor)
  enum :outdoor_location, {
    outdoor_01: 0,
    outdoor_02: 1,
    outdoor_03: 2
  }, prefix: true

  validates :outdoor_location, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Callback: ao criar um bloqueio, cancela rents pendentes que conflitam
  after_create :cancel_overlapping_pending_rents!

  scope :active, -> { where('end_date >= ?', Date.today) }
  scope :for_location, ->(location) { where(outdoor_location: location) }

  # Verifica se uma data específica está bloqueada para uma localização
  def self.blocked_on?(location, date)
    where(outdoor_location: location)
      .where('start_date <= ? AND end_date >= ?', date, date)
      .exists?
  end

  # Verifica se um período está bloqueado para uma localização (usando valor inteiro do enum)
  def self.blocked_between?(location, start_date, end_date)
    where(outdoor_location: location)
      .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
             start_date, start_date, end_date, end_date, start_date, end_date)
      .exists?
  end

  # Verifica se um período está bloqueado para uma localização (usando string do enum, ex: "outdoor_01")
  def self.location_blocked_for_period?(location_string, start_date, end_date)
    location_int = Outdoor.outdoor_locations[location_string.to_sym]
    return false unless location_int

    blocked_between?(location_int, start_date, end_date)
  end

  # Retorna a próxima data disponível para uma localização (aceita int ou string)
  def self.next_available_date_for_location(location)
    location_int = location.is_a?(Integer) ? location : Outdoor.outdoor_locations[location.to_sym]
    return Date.today + 5.days unless location_int

    latest_block = where(outdoor_location: location_int)
                    .where('end_date >= ?', Date.today)
                    .order(end_date: :desc)
                    .first

    if latest_block
      next_date = latest_block.end_date + 1.day
      # Garante que a data mínima seja pelo menos 5 dias à frente
      [next_date, Date.today + 5.days].max
    else
      Date.today + 5.days
    end
  end

  # Retorna a data mínima para o date picker considerando bloqueios da localização
  def self.minimum_start_date_for_location(location_string)
    base_min = Date.today + 5.days
    return base_min unless location_string.present?

    location_int = Outdoor.outdoor_locations[location_string.to_sym]
    return base_min unless location_int

    next_available = next_available_date_for_location(location_int)
    [base_min, next_available].max
  end

  # Busca rents pendentes que conflitam com este bloqueio
  def overlapping_pending_rents
    Rent.joins(:outdoor)
        .where(outdoors: { outdoor_location: Outdoor.outdoor_locations[outdoor_location.to_sym] })
        .where(status: 'pending')
        .where(
          '(rents.start_date <= ? AND rents.end_date >= ?) OR ' \
          '(rents.start_date <= ? AND rents.end_date >= ?) OR ' \
          '(rents.start_date >= ? AND rents.end_date <= ?)',
          start_date, start_date,
          end_date, end_date,
          start_date, end_date
        )
  end

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  def location_label
    Outdoor.outdoor_location_options.find { |opt| opt[1] == outdoor_location }&.first || outdoor_location
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'deve ser posterior à data inicial')
    end
  end

  # Cancela automaticamente rents pendentes que conflitam com o bloqueio criado
  def cancel_overlapping_pending_rents!
    conflicting = overlapping_pending_rents
    count = conflicting.count

    if count > 0
      conflicting.each do |rent|
        Rails.logger.info "🔒 Cancelando Rent ##{rent.id} (user: #{rent.user.email}) - conflito com bloqueio de localização #{location_label}"
        rent.update!(status: 'canceled')
      end
      Rails.logger.info "🔒 #{count} orçamento(s) pendente(s) cancelado(s) automaticamente pelo bloqueio de #{location_label}"
    end

    count
  end
end


