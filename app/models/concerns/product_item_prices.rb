module ProductItemPrices
  extend ActiveSupport::Concern

  included do
    has_many :product_prices, as: :subject, dependent: :destroy
    accepts_nested_attributes_for :product_prices, allow_destroy: true

    delegate :weight_of_price, :price_currency, to: :product

    attribute :price
    attribute :sale_price

    after_save :update_changed_prices, :update_product_sort_actual_price
  end

  def find_product_price_by_id(product_price_id)
    product_prices.find_by(id: product_price_id) || product.product_prices.find_by(id: product_price_id)
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def price
    return self[:price] if new_record? || price_changed?

    @cached_price ||= default_product_price.price
  end

  def sale_price
    return self[:sale_price] if new_record? || sale_price_changed?

    @cached_sale_price ||= sale_product_price.price
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def actual_price
    is_sale? ? sale_price : price
  end

  def actual_product_price
    is_sale? ? sale_product_price : default_product_price
  end

  def purchase_price
    ecr_nomenclature.try(:purchase_price) || product.purchase_price
  end

  def sale_product_price
    item_sale_product_price || product.sale_product_price
  end

  def default_product_price
    item_default_product_price || product.default_product_price
  end

  def item_sale_product_price
    product_prices.with_price.find_by(price_kind: vendor.sale_price_kind)
  end

  def item_default_product_price
    product_prices.with_price.find_by(price_kind: vendor.default_price_kind)
  end

  private

  def update_changed_prices
    find_or_create_product_price.update! price: price_previous_change.last if price_previous_change.present?
    find_or_create_product_sale_price.update! price: price_previous_change.last if price_previous_change.present?
  end

  def update_product_sort_actual_price
    product.update_sort_actual_price!
  end

  def find_or_create_product_price
    product_prices.create_with(vendor_id: vendor_id).find_or_create_by!(price_kind_id: vendor.default_price_kind_id)
  end

  def find_or_create_product_sale_price
    product_prices.create_with(vendor_id: vendor_id).find_or_create_by!(price_kind_id: vendor.sale_price_kind_id)
  end
end
