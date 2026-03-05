class CreateLocationBlockedFaces < ActiveRecord::Migration[7.2]
  def change
    create_table :location_blocked_faces do |t|
      t.integer :outdoor_location
      t.text :blocked_faces, default: '[]'
      t.date :start_date
      t.date :end_date
      t.string :reason
      t.integer :blocked_by

      t.timestamps
    end

    add_index :location_blocked_faces, :outdoor_location
    add_index :location_blocked_faces, [:start_date, :end_date]
  end
end
