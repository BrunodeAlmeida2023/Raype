class LocationBlockedFace < ApplicationRecord
  # Relacionamentos
  belongs_to :admin_user, class_name: 'User', foreign_key: 'blocked_by', optional: true

  # Serialização para armazenar array de faces
  serialize :blocked_faces, type: Array, coder: JSON

  # Enums para outdoor_location (deve coincidir com Outdoor model)
  enum outdoor_location: {
    outdoor_01: 0,
    outdoor_02: 1,
    outdoor_03: 2
  }

  # Validações
  validates :outdoor_location, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :blocked_faces, presence: true
  validate :end_date_after_start_date
  validate :valid_face_numbers

  # Scopes
  scope :active, -> { where('end_date >= ?', Date.today) }
  scope :for_location, ->(location) { where(outdoor_location: location) }

  # Verifica se uma face específica está bloqueada nesta data
  def self.face_blocked?(location, face_number, date)
    where(outdoor_location: location)
      .where('start_date <= ? AND end_date >= ?', date, date)
      .any? { |block| block.blocked_faces.include?(face_number) }
  end

  # Retorna as faces bloqueadas para uma localização em um período
  def self.blocked_faces_in_period(location, start_date, end_date)
    blocked = []
    where(outdoor_location: location)
      .where('start_date <= ? AND end_date >= ?', end_date, start_date)
      .each do |block|
        blocked.concat(block.blocked_faces)
      end
    blocked.uniq
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'deve ser posterior à data inicial')
    end
  end

  def valid_face_numbers
    return if blocked_faces.blank?

    invalid_faces = blocked_faces.reject { |face| [1, 2, 3].include?(face) }
    if invalid_faces.any?
      errors.add(:blocked_faces, 'contém números de face inválidos (permitido: 1, 2, 3)')
    end
  end
end
