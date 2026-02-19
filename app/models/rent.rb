class Rent < ApplicationRecord
  belongs_to :user
  belongs_to :outdoor

  # Validações básicas
  validates :start_date, :end_date, :total_amount, presence: true
  validate :outdoor_available_in_period, on: :create

  # Enum para facilitar o status (opcional, mas recomendado)
  # pending: aguardando pagto, paid: pago/ativo, finished: acabou o prazo
  enum status: { pending: 'pending', paid: 'paid', finished: 'finished', canceled: 'canceled' }

  # Escopo útil: Aluguéis ativos AGORA
  scope :active, -> { where(status: 'paid').where('end_date >= ?', Date.today) }

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
end