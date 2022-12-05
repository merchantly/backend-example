class ProductPrice < ApplicationRecord
  belongs_to :subject, polymorphic: true # Product, ProductItem
  belongs_to :price_kind
  has_many :cart_items, dependent: :destroy

  scope :with_price, -> { where.not(price_cents: nil) }

  monetize :price_cents,
           as: :price,
           with_model_currency: :price_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  delegate :vendor, to: :subject
  validate :validate_currency

  before_create do
    self.vendor_id ||= subject.vendor_id
  end

  after_update :update_min_max_prices

  # Тут может быть двойное обновление, если у товара тоже сработает подобный callback
  after_commit on: :update do
    subject.update_ordering!
  end

  delegate :sale?, to: :price_kind

  def is_default_or_sale?
    return false unless persisted?

    price_kind.is_default_or_sale?
  end

  def is_default?
    return false unless persisted?

    price_kind.default?
  end

  def available_for_client?(client_category)
    client_category.available_price_kinds.include? price_kind
  end

  private

  def update_min_max_prices
    if destroyed?
      # При массовом удалении будет очень тормозить
      price_kind.reset_min_max_product_prices!
    else
      attrs = {}

      attrs[:min_product_price] = price if price.present? && (price_kind.min_product_price.nil? || price_kind.min_product_price > price)
      attrs[:max_product_price] = price if price.present? && (price_kind.max_product_price.nil? || price_kind.max_product_price < price)
      price_kind.update attrs if attrs.present?
    end
  end

  def validate_currency
    return unless subject.present? && vendor.present? && price.is_a?(Money)
    return if price.currency == vendor.default_currency

    errors.add :price, I18n.t('errors.product.price.currencies_conflict', product_currency: price.currency, vendor_currency: vendor.default_currency)
  end
end
