class PaymentDiscounter
  include Virtus.model struct: true

  attribute :order, Order
  attribute :total_price, Money

  delegate :payment_type, :delivery_type, :vendor, to: :order

  def perform
    return if discount.blank?

    case discount_type
    when :percent
      Discounting.new(
        discount: discount,
        discount_price: (total_price - percent_total_discounted),
        total_discounted: percent_total_discounted
      )
    when :fixed
      Discounting.new(
        discount: 0,
        discount_price: fixed_discount,
        total_discounted: (total_price - fixed_discount)
      )
    else
      raise "unknown #{discount.discount_type}"
    end
  end

  private

  def fixed_discount
    Money.new(discount * vendor.default_currency.subunit_to_unit, vendor.default_currency)
  end

  def percent_total_discounted
    dp = (total_price * discount / 100).exchange_to total_price.currency
    return vendor.zero_money if dp >= total_price

    total_price - dp
  end

  def discount
    payment_to_delivery.try(:discount)
  end

  def discount_type
    payment_to_delivery.discount_type.to_sym
  end

  def payment_to_delivery
    return if payment_type.blank?

    @payment_to_delivery ||= payment_type.discount_for_delivery(delivery_type)
  end
end
