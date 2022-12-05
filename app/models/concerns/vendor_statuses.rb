module VendorStatuses
  def payments_on?
    w1_on?
  end

  # Платежи через w1 настроены и осущствляются?
  def w1_payments_on?
    # TODO учитывать реальное существование оплаченных через walletone заказов
    w1_on?
  end

  def stock_on?
    stock_success_synced_at.present?
  end

  def ordering?
    default_delivery_type.present?
  end

  def order_stocking_only?
    ms_valid? && is_ordering_stock_linked_only?
  end
end
