class AddFaceFieldsToOutdoors < ActiveRecord::Migration[7.2]
  def change
    add_column :outdoors, :has_own_art, :boolean, default: true
    add_column :outdoors, :selected_faces, :text, default: '[]'
  end
end
