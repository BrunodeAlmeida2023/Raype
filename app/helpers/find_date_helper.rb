module FindDateHelper
  def minimum_start_date
    (Date.today + 5).to_s
  end
  def show_triedo_warning?(outdoor)
    outdoor&.outdoor_type == 'triedo'
  end
  def triedo_warning_message
    {
      title: "Atenção - Outdoor Triedo:",
      message: "O outdoor triedo possui um tempo mínimo de 5 dias úteis para fabricação e instalação após a confirmação do pagamento."
    }
  end
  def date_form_hint
    "* A data final deve ser no mínimo 1 mês após a data inicial."
  end
end
