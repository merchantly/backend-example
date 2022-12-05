module ProductPrices
  extend ActiveSupport::Concern

  included do
    has_many :product_prices, as: :subject, dependent: :destroy
    accepts_nested_attributes_for :product_prices, reject_if: :all_blank, allow_destroy: true

    before_update :update_changed_prices

    after_create :create_product_prices
    after_save :update_product_fields, if: :saved_change_to_archived_at?

    attribute :price
    attribute :sale_price

    attr_reader :price_was, :sale_price_was

    # Используем для удобной сортировки товаров по цене
    monetize :sort_actual_price_cents,
             as: :sort_actual_price,
             allow_nil: true,
             with_model_currency: :sort_actual_price_currency,
             numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

    before_validation :set_sort_actual_price, if: -> { will_save_change_to_is_sale? || will_save_change_to_price? }
  end

  def find_product_price_by_id(product_price_id)
    product_prices.find_by(id: product_price_id)
  end

  def default_product_price
    return product_prices.build(price_kind: vendor.default_price_kind) if new_record?

    product_prices.find_or_create_by!(price_kind: vendor.default_price_kind)
  end

  def sale_product_price
    return product_prices.build(price_kind: vendor.sale_price_kind) if new_record?

    product_prices.find_or_create_by!(price_kind: vendor.sale_price_kind)
  end

  def actual_price
    is_sale? ? sale_price : price
  end

  def actual_product_price
    is_sale? ? sale_product_price : default_product_price
  end

  def sale_percent
    return if sale_price.nil? || price.nil? || price.amount.zero?

    (100 - (sale_price * 100 / price)).round
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def sale_price
    return self[:sale_price] if new_record? || sale_price_changed?

    @cached_sale_price ||= sale_product_price.price
  end

  def price
    return self[:price] if new_record? || price_changed?

    @cached_price ||= default_product_price.price
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def actual_price=(value)
    if is_sale?
      self.sale_price = value
    else
      self.price = value
    end
  end

  def set_sort_actual_price
    self.sort_actual_price = build_sort_actual_price
  end

  def update_sort_actual_price!
    set_sort_actual_price
    save!
  end

  private

  def update_changed_prices
    default_product_price.update! price: price if will_save_change_to_price?
    sale_product_price.update! price: sale_price if will_save_change_to_sale_price?
  end

  def create_product_prices
    # Цены могут придти через accepts_nested_attributes_for
    product_prices
      .create_with(price: price_previous_change.try(:last), vendor_id: vendor_id)
      .find_or_create_by!(price_kind_id: vendor.default_price_kind_id)
    product_prices
      .create_with(price: sale_price_previous_change.try(:last), vendor_id: vendor_id)
      .find_or_create_by!(price_kind_id: vendor.sale_price_kind_id)
  end

  def build_sort_actual_price
    if goods.present?
      goods.map(&:actual_price).compact.min
    else
      actual_price
    end
  end
end
