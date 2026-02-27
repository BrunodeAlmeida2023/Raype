class AddCustomArtQuantityToOutdoors < ActiveRecord::Migration[7.2]
  def change
    add_column :outdoors, :custom_art_quantity, :integer
  end
end
