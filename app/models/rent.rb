class Rent < ApplicationRecord
  belongs_to :user
  belongs_to :outdoor

  # Validações básicas
  validates :start_date, :end_date, :total_amount, presence: true
  validate :outdoor_available_in_period, on: :create
  validate :location_not_blocked, on: :create
  validate :faces_not_blocked, on: :create

  # Enum para facilitar o status (opcional, mas recomendado)
  # pending: aguardando pagto, paid: pago/ativo, finished: acabou o prazo
  enum status: { pending: 'pending', paid: 'paid', finished: 'finished', canceled: 'canceled' }

  # Escopo útil: Aluguéis ativos AGORA
  scope :active, -> { where(status: 'paid').where('end_date >= ?', Date.today) }

  # Verifica se este rent está em conflito com bloqueio de localização ou faces do admin
  def blocked_by_admin?
    return false unless outdoor&.outdoor_location.present? && start_date && end_date

    # Verifica bloqueio de localização completa
    location_blocked = LocationBlockedDate.location_blocked_for_period?(outdoor.outdoor_location, start_date, end_date)
    return true if location_blocked

    # Verifica bloqueio de faces específicas
    faces_blocked_by_admin?
  end

  # Verifica se as faces específicas deste rent estão bloqueadas
  def faces_blocked_by_admin?
    return false unless outdoor&.outdoor_location.present? && outdoor.selected_faces.present?
    return false unless start_date && end_date

    blocked_faces = LocationBlockedFace.blocked_faces_in_period(
      outdoor.outdoor_location,
      start_date,
      end_date
    )

    # Verifica se alguma das faces selecionadas está bloqueada
    (outdoor.selected_faces & blocked_faces).any?
  end

  private

  def outdoor_available_in_period
    return unless outdoor_id && start_date && end_date

    # Busca rents PAGOS do mesmo outdoor que conflitam com as datas
    conflicting_rents = Rent.where(outdoor_id: outdoor_id, status: 'paid')
                           .where('start_date < ? AND end_date > ?', end_date, start_date)

    if conflicting_rents.exists?
      conflicting_rent = conflicting_rents.first
      errors.add(:base, "Este outdoor já está alugado no período selecionado. " \
                        "O outdoor está reservado de #{conflicting_rent.start_date.strftime('%d/%m/%Y')} " \
                        "até #{conflicting_rent.end_date.strftime('%d/%m/%Y')}. " \
                        "Por favor, escolha outras datas ou outro outdoor.")
    end
  end

  def location_not_blocked
    return unless outdoor&.outdoor_location.present? && start_date && end_date

    if LocationBlockedDate.location_blocked_for_period?(outdoor.outdoor_location, start_date, end_date)
      next_available = LocationBlockedDate.minimum_start_date_for_location(outdoor.outdoor_location)
      errors.add(:base, "Este período não está disponível para a localização selecionada. " \
                        "Próxima data disponível: #{next_available.strftime('%d/%m/%Y')}. " \
                        "Por favor, escolha outras datas.")
    end
  end

  def faces_not_blocked
    return unless outdoor&.outdoor_location.present? && outdoor.selected_faces.present?
    return unless start_date && end_date

    blocked_faces = LocationBlockedFace.blocked_faces_in_period(
      outdoor.outdoor_location,
      start_date,
      end_date
    )

    blocked_selected = outdoor.selected_faces & blocked_faces
    if blocked_selected.any?
      errors.add(:base, "Face(s) #{blocked_selected.join(', ')} do outdoor não está(ão) disponível(is) para o período selecionado. " \
                        "Essas faces foram bloqueadas pelo administrador. " \
                        "Por favor, selecione outras faces ou escolha outro período.")
    end
  end
end