class AddStartAndEndDateToOutdoors < ActiveRecord::Migration[7.2]
  def change
    add_column :outdoors, :selected_start_date, :date
    add_column :outdoors, :selected_end_date, :date
  end
end
