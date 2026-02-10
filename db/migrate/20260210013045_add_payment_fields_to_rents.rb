class AddPaymentFieldsToRents < ActiveRecord::Migration[7.2]
  def change
    add_column :rents, :payment_method, :string
    add_column :rents, :asaas_payment_url, :text
  end
end
