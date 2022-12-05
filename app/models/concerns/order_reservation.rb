module OrderReservation
  def reserve_items_on_stock!
    order_local_stock.reserve!
    order_remote_stock.reserve! if reserve_on_remote_stock?
  end

  def unreserve_items_on_stock!
    order_local_stock.unreserve!
    order_remote_stock.unreserve!
  end

  def reserve_on_remote_stock?
    vendor.reserve_order_on_stock?
  end

  def is_full_reserved?
    if reserve_on_remote_stock?
      is_both_reserved?
    else
      order_local_stock.is_reserved?
    end
  end

  def is_both_reserved?
    order_local_stock.is_reserved? && order_remote_stock.is_reserved?
  end

  def is_reserved?
    order_local_stock.is_reserved? || order_remote_stock.is_reserved?
  end
end
