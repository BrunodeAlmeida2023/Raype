class AddDocumentFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :documento_tipo, :string, default: 'cpf'
    add_column :users, :documento_numero, :string

    # Atualizar usuários existentes com documento padrão
    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.where(documento_numero: nil).update_all(documento_numero: '00000000000')
      end
    end

    # Depois adicionar constraints
    change_column_null :users, :documento_tipo, false
    change_column_null :users, :documento_numero, false

    add_index :users, :documento_numero, unique: true
  end
end
