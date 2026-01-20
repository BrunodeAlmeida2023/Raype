class Outdoor < ApplicationRecord
  belongs_to :user

  # Attachments para as artes do outdoor (até 3 artes)
  has_many_attached :art_files

  # Enum para tipo de outdoor
  enum :outdoor_type, {
    triedo: 0,
    led: 1,
    digital: 2
  }, prefix: true

  # Enum para localização do outdoor
  enum :outdoor_location, {
    outdoor_01: 0,  # Logo frente ao no ponto super mercado
    outdoor_02: 1,  # Proximo ao Dogão Sul
    outdoor_03: 2   # Sobre guarita das pontes DV
  }, prefix: true

  # Enum para status do outdoor (em qual etapa está)
  enum :status, {
    pending: 0,           # Aguardando inicio
    outdoor_selected: 1,  # Outdoor selecionado
    date_selected: 2,     # Data selecionada
    art_uploaded: 3,      # Arte enviada
    completed: 4          # Concluído
  }, prefix: true

  # Validações
  validates :user, presence: true

  # Scopes úteis
  scope :recent, -> { order(created_at: :desc) }
  scope :completed_outdoors, -> { where(status: :completed) }
  scope :in_progress, -> { where.not(status: [:pending, :completed]) }

  # Métodos de classe para retornar opções para select
  def self.outdoor_type_options
    [
      ['Outdoor Triedo', 'triedo'],
      ['Outdoor LED', 'led']
    ]
  end

  def self.outdoor_location_options
    [
      ['Logo frente ao no ponto super mercado', 'outdoor_01'],
      ['Proximo ao Dogão Sul', 'outdoor_02'],
      ['Sobre guarita das pontes DV', 'outdoor_03']
    ]
  end

  def self.outdoor_size_options
    [
      ['Pequeno (3x2m)', 'pequeno'],
      ['Médio (5x3m)', 'medio']
    ]
  end

  # Métodos de instância
  def outdoor_type_label
    self.class.outdoor_type_options.find { |opt| opt[1] == outdoor_type }&.first || outdoor_type
  end

  def outdoor_location_label
    self.class.outdoor_location_options.find { |opt| opt[1] == outdoor_location }&.first || outdoor_location
  end

  def outdoor_size_label
    self.class.outdoor_size_options.find { |opt| opt[1] == outdoor_size }&.first || outdoor_size
  end

  def next_step!
    case status
    when 'pending'
      status_outdoor_selected!
    when 'outdoor_selected'
      status_date_selected!
    when 'date_selected'
      status_art_uploaded!
    when 'art_uploaded'
      status_completed!
    end
  end
end

