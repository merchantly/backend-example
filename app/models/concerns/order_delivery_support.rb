module OrderDeliverySupport
  extend ActiveSupport::Concern

  included do
    has_one :order_delivery
    belongs_to :delivery_type, class_name: 'VendorDelivery'

    after_create :create_delivery

    scope :by_delivery_external_id, ->(id) { joins(:order_delivery).where(order_deliveries: { external_id: id }) }

    scope :delivery_expired, lambda {
      fresh.includes(:order_delivery)
           .where(orders: { is_delivery_expiration_notified: false })
           .where('order_deliveries.expires_at IS NOT NULL AND order_deliveries.expires_at < ?', 1.day.from_now)
           .where('order_deliveries.type' => 'OrderDeliveryPickup')
           .references(:order_deliveries)
    }

    monetize :free_delivery_threshold_cents,
             as: :free_delivery_threshold,
             with_model_currency: :free_delivery_threshold_currency,
             numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }
  end

  def calculated_free_delivery?
    (calculated_free_delivery_threshold.positive? && (calculated_total_price >= calculated_free_delivery_threshold)) ||
      (coupon.present? && free_delivery?)
  end

  def free_delivery?
    (free_delivery_threshold.positive? && calculated_total_price >= free_delivery_threshold) ||
      (coupon.present? && coupon.free_delivery? && discounting.free_delivery)
  end

  private

  def calculated_delivery_price
    return zero_money if calculated_free_delivery?
    return if delivery_type.blank?

    price = if delivery_type.is_yandex_delivery?
              yandex_delivery.price
            elsif delivery_type.is_cdek_delivery?
              cdek_delivery.price
            else
              delivery_type.price
            end

    return unless price.is_a? Money

    price.exchange_to currency
  end

  def calculated_free_delivery_threshold
    (delivery_type.try(:free_delivery_threshold) || zero_money).exchange_to currency
  end

  def create_delivery
    delivery_type.agent_class.create! order_id: id
  end
end
