class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Relacionamentos
  has_one :outdoor, dependent: :destroy

  has_many :rents
  has_many :outdoors, through: :rents

  # Validações de documento
  validates :documento_tipo, presence: true, inclusion: { in: %w[cpf cnpj] }
  validates :documento_numero, presence: true, uniqueness: true
  validate :documento_valido

  # Normalizar documento antes de salvar (remover pontos, traços, etc)
  before_validation :normalizar_documento

  private

  def normalizar_documento
    return unless documento_numero
    self.documento_numero = documento_numero.gsub(/[^\d]/, '')
  end

  def documento_valido
    return if documento_numero.blank?

    if documento_tipo == 'cpf'
      unless CPF.valid?(documento_numero)
        errors.add(:documento_numero, 'CPF inválido')
      end
    elsif documento_tipo == 'cnpj'
      unless CNPJ.valid?(documento_numero)
        errors.add(:documento_numero, 'CNPJ inválido')
      end
    end
  end
end
