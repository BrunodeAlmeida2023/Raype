class CreateLocationBlockedDates < ActiveRecord::Migration[7.2]
  def change
    create_table :location_blocked_dates do |t|
      t.integer :outdoor_location
      t.date :start_date
      t.date :end_date
      t.string :reason
      t.integer :blocked_by

      t.timestamps
    end
  end
end
