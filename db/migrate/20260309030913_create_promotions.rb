class CreatePromotions < ActiveRecord::Migration[7.2]
  def change
    create_table :promotions do |t|
      t.integer :outdoor_location
      t.integer :promotion_type
      t.decimal :original_price, precision: 10, scale: 2
      t.decimal :promotional_price, precision: 10, scale: 2
      t.boolean :active, default: true
      t.date :start_date
      t.date :end_date
      t.text :description
      t.integer :created_by

      t.timestamps
    end

    add_index :promotions, :outdoor_location
    add_index :promotions, :promotion_type
    add_index :promotions, :active
    add_index :promotions, [:start_date, :end_date]
  end
end

