module ChooseArtHelper
  # 🚀 OTIMIZAÇÃO: Carrega URLs apenas se necessário
  def saved_art_urls(outdoor)
    return [] unless outdoor&.art_files&.attached?
    return [] unless outdoor.has_own_art # Não precisa carregar se não tem arte própria

    # Usa variant thumb para preview (mais rápido)
    outdoor.art_files.map do |art_file|
      begin
        url_for(art_file.variant(:thumb))
      rescue
        url_for(art_file) # Fallback para original se variant falhar
      end
    end
  end

  def choose_art_ownership_value(outdoor)
    return '' if outdoor.nil? || outdoor.has_own_art.nil?
    outdoor.has_own_art.to_s
  end

  def face_selected?(outdoor, face_number)
    return false if outdoor.nil? || outdoor.selected_faces.blank?
    outdoor.selected_faces.include?(face_number)
  end

  def show_outdoor_preview?(outdoor)
    outdoor&.outdoor_type == 'triedo'
  end

  def face_options_for_select
    [
      ['Face 1', 1],
      ['Face 2', 2],
      ['Face 3', 3]
    ]
  end

  def faces_display_text(faces_array)
    return 'Nenhuma face selecionada' if faces_array.blank?
    "Face(s) #{faces_array.join(', ')}"
  end
end

