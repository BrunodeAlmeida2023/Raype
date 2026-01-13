class CreateOutdoors < ActiveRecord::Migration[7.2]
  def change
    create_table :outdoors do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :outdoor_type, default: 0
      t.integer :outdoor_location, default: 0
      t.string :outdoor_size
      t.date :selected_date
      t.text :art_description
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :outdoors, :status
    add_index :outdoors, :outdoor_type
  end
end
