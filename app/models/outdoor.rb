class Outdoor < ApplicationRecord
  belongs_to :user

  # Attachments para as artes do outdoor (até 3 artes)
  has_many_attached :art_files do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :medium, resize_to_limit: [800, 800]
  end

  # 🔒 Validações de segurança para arquivos
  validates :art_files,
            content_type: { in: ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp'],
                           message: 'deve ser uma imagem válida (PNG, JPG, JPEG, GIF ou WebP)' },
            size: { less_than: 5.megabytes, message: 'deve ser menor que 5MB' },
            if: -> { art_files.attached? }

  has_many :rents
  has_many :blocked_dates, class_name: 'OutdoorBlockedDate', dependent: :destroy

  # Serialização para array de faces selecionadas
  serialize :selected_faces, type: Array, coder: JSON

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
  validate :validate_end_date_period
  validate :validate_selected_faces

  # Callbacks
  before_save :ensure_custom_art_quantity
  before_save :ensure_selected_faces_array

  # Scopes úteis
  scope :recent, -> { order(created_at: :desc) }
  scope :completed_outdoors, -> { where(status: :completed) }
  scope :in_progress, -> { where.not(status: [:pending, :completed]) }

  # Métodos de classe para retornar opções para select
  def self.outdoor_type_options
    [
      ['Outdoor Triedo', 'triedo']
      # ['Outdoor LED', 'led']
    ]
  end

  def self.outdoor_location_options
    [
      ['Morro da coruja', 'outdoor_01']
    ]
  end

  def self.outdoor_size_options
    [
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

  def available?(date = Date.today)
    # Procura se existe algum aluguel PAGO que cubra essa data
    rents.where(status: 'paid')
         .where('start_date <= ? AND end_date >= ?', date, date)
         .empty?
  end

  # Calcula a duração em meses entre selected_start_date e selected_end_date
  def duration_in_months
    return 0 unless selected_start_date.present? && selected_end_date.present?

    (selected_end_date.year - selected_start_date.year) * 12 +
    (selected_end_date.month - selected_start_date.month)
  end

  # Retorna o número total de artes baseado nas faces selecionadas
  def total_arts_count
    return 0 if selected_faces.blank?
    selected_faces.size
  end

  # Verifica se o usuário tem arte própria ou precisa de criação
  def needs_art_creation?
    has_own_art == false
  end

  # Retorna faces disponíveis para seleção (não bloqueadas)
  def self.available_faces_for_location(location, start_date, end_date)
    all_faces = [1, 2, 3]
    return all_faces if start_date.blank? || end_date.blank?

    blocked = LocationBlockedFace.blocked_faces_in_period(location, start_date, end_date)
    all_faces - blocked
  end

  private

  def validate_end_date_period
    # Só valida se ambas as datas estiverem preenchidas
    return unless selected_start_date.present? && selected_end_date.present?

    # 1. Data final deve ser posterior à inicial
    if selected_end_date <= selected_start_date
      errors.add(:selected_end_date, "deve ser posterior à data inicial")
      return
    end

    # 2. Deve ter o mesmo dia do mês (meses completos)
    if selected_start_date.day != selected_end_date.day
      errors.add(:selected_end_date, "deve ter o mesmo dia do mês que a data inicial (dia #{selected_start_date.day})")
      return
    end

    # 3. Deve ser pelo menos 1 mês de diferença
    months_diff = duration_in_months
    if months_diff < 1
      errors.add(:selected_end_date, "deve ser no mínimo 1 mês após a data inicial")
      return
    end

    # 4. Verifica se o período está bloqueado pela localização (se já tiver location definida)
    if outdoor_location.present?
      if LocationBlockedDate.location_blocked_for_period?(outdoor_location, selected_start_date, selected_end_date)
        next_available = LocationBlockedDate.minimum_start_date_for_location(outdoor_location)
        errors.add(:base, "Este período não está disponível para a localização selecionada. " \
                          "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}")
      end
    end
  end

  def ensure_custom_art_quantity
    # Força Rails a reconhecer mudanças no custom_art_quantity
    # Usa total_arts_count que nunca é nil (ao invés de art_quantity deprecated)
    arts_count = total_arts_count || 0

    if arts_count == 0 && custom_art_quantity.present?
      self.custom_art_quantity = custom_art_quantity.to_i
    elsif arts_count != 0
      self.custom_art_quantity = nil
    end
  end

  def ensure_selected_faces_array
    # Garante que selected_faces seja sempre um array
    self.selected_faces = [] if selected_faces.nil?
    self.selected_faces = selected_faces.compact.uniq.sort
  end

  def validate_selected_faces
    return if selected_faces.blank?

    # Valida se as faces são números válidos (1, 2 ou 3)
    invalid_faces = selected_faces.reject { |face| [1, 2, 3].include?(face) }
    if invalid_faces.any?
      errors.add(:selected_faces, 'contém números de face inválidos')
      return
    end

    # Verifica se as faces estão disponíveis (não bloqueadas) no período selecionado
    if outdoor_location.present? && selected_start_date.present? && selected_end_date.present?
      blocked_faces = LocationBlockedFace.blocked_faces_in_period(
        outdoor_location,
        selected_start_date,
        selected_end_date
      )

      blocked_selected = selected_faces & blocked_faces
      if blocked_selected.any?
        errors.add(:selected_faces, "Face(s) #{blocked_selected.join(', ')} não disponível(is) para o período selecionado")
      end
    end
  end
end

