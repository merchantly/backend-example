module MaxOrderItemsCountValidation
  extend ActiveSupport::Concern

  YANDEX_MAX_ITEMS_COUNT = 100

  included do
    validate :validate_max_order_items_count
    validate :validate_max_order_similar_products_count
    validate :validate_yandex_kassa_max_items_count
  end

  private

  def validate_max_order_items_count
    return if items.count <= vendor.max_order_items_count

    errors.add(:max_order_items_count, I18n.vt('errors.cart.max_order_items_count', max_count: vendor.max_order_items_count))
  end

  def validate_max_order_similar_products_count
    return if items.find { |i| i.quantity > vendor.max_order_similar_products_count }.blank?

    errors.add(:max_order_similar_products_count, I18n.vt('errors.cart.max_order_similar_products_count', max_count: vendor.max_order_similar_products_count))
  end

  def validate_yandex_kassa_max_items_count
    return unless respond_to?(:payment_type) && payment_type.present?
    return unless payment_type.yandex_kassa? && payment_type.online_kassa_provider_default?

    if discount?
      return unless items.sum(&:quantity) > YANDEX_MAX_ITEMS_COUNT
    else
      return unless items.count > YANDEX_MAX_ITEMS_COUNT
    end

    errors.add(:yandex_kassa_max_items_count, I18n.vt('errors.order.yandex_kassa_max_items_count', max_count: YANDEX_MAX_ITEMS_COUNT))
  end

  def discount?
    coupon_code.present? || payment_type.discount_for_delivery(delivery_type).try(:discount).present?
  end
end
