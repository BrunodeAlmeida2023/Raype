class CreateRents < ActiveRecord::Migration[7.2]
  def change
    create_table :rents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :outdoor, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :total_amount
      t.string :status
      t.string :asaas_id

      t.timestamps
    end
  end
end
