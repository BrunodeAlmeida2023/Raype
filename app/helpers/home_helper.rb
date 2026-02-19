module HomeHelper
  def outdoor_completed?(outdoor)
    outdoor&.outdoor_type.present? &&
    outdoor&.outdoor_size.present? &&
    outdoor&.outdoor_location.present?
  end

  def date_completed?(outdoor)
    outdoor&.selected_start_date.present? &&
    outdoor&.selected_quantity_month.present? &&
    outdoor.selected_quantity_month > 0
  end

  def art_completed?(outdoor)
    outdoor&.art_quantity.present? &&
    outdoor.art_quantity >= 0 &&
    (outdoor.art_quantity == 0 || outdoor.art_files&.attached?)
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
end
