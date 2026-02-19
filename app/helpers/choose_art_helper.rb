module ChooseArtHelper
  def saved_art_urls(outdoor)
    return [] unless outdoor&.art_files&.attached?
    outdoor.art_files.map { |art_file| url_for(art_file) }
  end
  def saved_art_data_json(outdoor)
    {
      art_quantity: outdoor&.art_quantity || 0,
      saved_arts: saved_art_urls(outdoor)
    }.to_json
  end
  def art_quantity_options(selected = nil)
    options = [
      ['Nenhuma (quero que criem para mim)', 0],
      ['1 arte', 1],
      ['2 artes', 2],
      ['3 artes', 3]
    ]
    options_for_select(options, selected || 0)
  end
  def show_outdoor_preview?(outdoor)
    outdoor&.outdoor_type == 'triedo'
  end
end
