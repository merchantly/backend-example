class OrderLocalStock < ApplicationRecord
  belongs_to :order

  delegate :vendor, :items, :run_out_goods, to: :order

  def reserve!
    return if is_reserved?

    transaction do
      items.find_each(&:reserve!) unless vendor.reserve_order_on_stock?
      update! is_reserved: true, reserved_at: Time.zone.now

      goods_run_out_vendor_notify if run_out_goods.any?
    end
  end

  def unreserve!
    return unless is_reserved?

    transaction do
      items.find_each(&:unreserve!) unless vendor.reserve_order_on_stock?
      update! is_reserved: false, unreserved_at: Time.zone.now
    end
  end

  private

  def goods_run_out_vendor_notify
    OrderNotificationService.new(order).order_has_run_out_goods
  end
end
