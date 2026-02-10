class Rent < ApplicationRecord
  belongs_to :user
  belongs_to :outdoor

  # Validações básicas
  validates :start_date, :end_date, :total_amount, presence: true

  # Enum para facilitar o status (opcional, mas recomendado)
  # pending: aguardando pagto, paid: pago/ativo, finished: acabou o prazo
  enum status: { pending: 'pending', paid: 'paid', finished: 'finished', canceled: 'canceled' }

  # Escopo útil: Aluguéis ativos AGORA
  scope :active, -> { where(status: 'paid').where('end_date >= ?', Date.today) }
end