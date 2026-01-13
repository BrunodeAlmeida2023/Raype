class AddArtQuantityToOutdoors < ActiveRecord::Migration[7.2]
  def change
    add_column :outdoors, :art_quantity, :integer
  end
end
