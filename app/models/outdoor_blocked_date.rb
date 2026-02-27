class OutdoorBlockedDate < ApplicationRecord
  belongs_to :outdoor
  belongs_to :admin_user, class_name: 'User', foreign_key: 'blocked_by', optional: true

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :active, -> { where('end_date >= ?', Date.today) }
  scope :for_outdoor, ->(outdoor_id) { where(outdoor_id: outdoor_id) }

  # Verifica se uma data específica está bloqueada
  def self.blocked_on?(outdoor_id, date)
    where(outdoor_id: outdoor_id)
      .where('start_date <= ? AND end_date >= ?', date, date)
      .exists?
  end

  # Verifica se um período está bloqueado
  def self.blocked_between?(outdoor_id, start_date, end_date)
    where(outdoor_id: outdoor_id)
      .where('(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
             start_date, start_date, end_date, end_date, start_date, end_date)
      .exists?
  end

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'deve ser posterior à data inicial')
    end
  end
end


