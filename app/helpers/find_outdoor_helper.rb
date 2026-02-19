module FindOutdoorHelper
  def outdoor_type_options_select(selected = nil)
    options_for_select(Outdoor.outdoor_type_options, selected)
  end
  def outdoor_size_options_select(selected = nil)
    options_for_select(Outdoor.outdoor_size_options, selected)
  end
  def outdoor_location_options_select(selected = nil)
    options_for_select(Outdoor.outdoor_location_options, selected)
  end
  def location_map_url
    "https://www.google.com/maps/place/Dois+Vizinhos,+PR,+85660-000/@-25.7501245,-53.0667007,14z/data=!3m1!4b1!4m6!3m5!1s0x94f047ed43a4d2dd:0xc57179d696514a97!8m2!3d-25.7511034!4d-53.0606298!16s%2Fg%2F1yy3vkg2x?entry=ttu&g_ep=EgoyMDI2MDEwNy4wIKXMDSoASAFQAw%3D%3D"
  end
end
