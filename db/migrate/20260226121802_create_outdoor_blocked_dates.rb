class CreateOutdoorBlockedDates < ActiveRecord::Migration[7.2]
  def change
    create_table :outdoor_blocked_dates do |t|
      t.references :outdoor, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :reason
      t.integer :blocked_by

      t.timestamps
    end
  end
end
