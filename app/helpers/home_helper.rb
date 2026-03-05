module HomeHelper
  def outdoor_completed?(outdoor)
    outdoor&.outdoor_type.present? &&
    outdoor&.outdoor_size.present? &&
    outdoor&.outdoor_location.present?
  end

  def date_completed?(outdoor)
    return false unless outdoor&.selected_start_date.present? &&
                        outdoor&.selected_end_date.present?

    # Se as datas estão bloqueadas pelo admin, considera como incompleto
    !outdoor_dates_blocked?(outdoor)
  end

  def art_completed?(outdoor)
    return false unless outdoor&.art_quantity.present?

    # Se art_quantity = 0 (sem arte), precisa ter custom_art_quantity
    if outdoor.art_quantity == 0
      return outdoor.custom_art_quantity.present? && outdoor.custom_art_quantity > 0
    end

    # Se tem art_quantity > 0, precisa ter os arquivos anexados
    outdoor.art_quantity > 0 && outdoor.art_files&.attached?
  end

  def all_steps_completed?(outdoor)
    outdoor_completed?(outdoor) &&
    date_completed?(outdoor) &&
    art_completed?(outdoor)
  end

  def user_has_blocking_rent?(user)
    user.rents.where(status: ['pending', 'paid']).exists?
  end

  def user_pending_rent(user)
    user.rents.where(status: 'pending').first
  end

  def user_paid_rent(user)
    user.rents.where(status: 'paid').first
  end

  def finalize_button_tooltip(has_paid, has_pending)
    if has_paid
      'Você já possui um pedido pago. Entre em contato via WhatsApp para alterações.'
    elsif has_pending
      'Finalize seu pagamento para continuar. Há um outdoor em orçamento para ser pago.'
    else
      ''
    end
  end

  # 🔒 Verifica se as datas salvas no outdoor estão bloqueadas por localização
  def outdoor_dates_blocked?(outdoor)
    return false unless outdoor&.outdoor_location.present? &&
                        outdoor&.selected_start_date.present? &&
                        outdoor&.selected_end_date.present?

    LocationBlockedDate.location_blocked_for_period?(outdoor.outdoor_location, outdoor.selected_start_date, outdoor.selected_end_date)
  end

  def date_range_options_for_select(start_date)
    return [] unless start_date.is_a?(Date)

    options = []
    (1..3).each do |months|
      end_date = start_date + months.months
      label = "#{end_date.strftime('%d/%m/%Y')} (#{months} #{months == 1 ? 'mês' : 'meses'})"
      options << [label, end_date.to_s]
    end
    options
  end
end
