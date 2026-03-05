class ReplaceQuantityMonthWithEndDate < ActiveRecord::Migration[7.2]
  def up
    # Remove the old column if it exists
    if column_exists?(:outdoors, :selected_quantity_month)
      remove_column :outdoors, :selected_quantity_month
    end

    # Add the new end date column if it doesn't exist
    unless column_exists?(:outdoors, :selected_end_date)
      add_column :outdoors, :selected_end_date, :date
    end
  end

  def down
    # Revert changes
    unless column_exists?(:outdoors, :selected_quantity_month)
      add_column :outdoors, :selected_quantity_month, :integer
    end

    if column_exists?(:outdoors, :selected_end_date)
      remove_column :outdoors, :selected_end_date
    end
  end
end


