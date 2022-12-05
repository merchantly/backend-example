class OrderItem < ApplicationRecord
  include Authority::Abilities
  include GoodItem
  include OrderItemWarehouseIssue

  # Испольуется для вычисления vat amount
  # перед созданием заказа
  attr_accessor :vendor_id

  # Счетчик умышленно не считаем, потому что в таком случае на каждое добовление товара
  # этот счетчик обновляется. Проще его сразу установить в правильное значение при создании заказа
  # , counter_cache: :items_count
  belongs_to :order
  has_one :order_payment, through: :order
  has_one :payment_type, through: :order

  has_many :warehouse_movements, class_name: 'Ecr::WarehouseMovement'
  has_many :refund_order_items, class_name: 'Ecr::RefundOrderItem'

  belongs_to :digital_key

  belongs_to :promotion

  before_validation do
    self.price = good.price if (price.nil? || price.zero?) && good.present?
  end

  monetize :price_cents, as: :price,
                         with_model_currency: :price_currency,
                         allow_nil: false,
                         numericality: { greater_than: 0, less_than: Settings.maximal_money }

  monetize :purchase_price_cents, as: :purchase_price,
                                  with_model_currency: :purchase_price_currency,
                                  allow_nil: true,
                                  numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money, allow_nil: true }

  monetize :total_sale_amount_cents, as: :total_sale_amount,
                                     with_model_currency: :total_sale_amount_currency,
                                     allow_nil: false,
                                     numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money, allow_nil: true }

  monetize :vat_cents, as: :vat, allow_nil: true

  validates :price,     presence: true
  validates :title,     presence: true
  validates :count,     presence: true, numericality: { greater_than: 0 }
  validates :weight,    numericality: { greater_than: 0, allow_blank: true }

  delegate :is_digital, :is_digital?, :quantity_unit, :tax_type, to: :good_or_custom_amount

  translates :title

  before_create :init_vats
  after_create :save_digital_key

  scope :payed, -> { joins(:order_payment).where(order_payments: { state: :paid }) }

  before_destroy do
    raise "Oops: cannot be deleted #{id}" if Rails.env.production?
  end

  def order_price
    order.order_prices.find_by_item self
  end

  def vendor
    @vendor ||= vendor_id.present? ? Vendor.find(vendor_id) : order.vendor
  end

  def good_or_custom_amount
    good || CustomAmount.new(vendor: vendor)
  end

  def download_url(params = {})
    return unless is_digital?

    Rails.application.routes.url_helpers.vendor_order_item_url params.merge id: id, host: vendor.home_url
  end

  def is_downloading_available?
    (order.paid? || order.success?) && is_digital? && !is_digital_key_available? && file_downloaded_count < ProductDigital::MAX_GENERATES
  end

  def is_digital_key_available?
    (order.paid? || order.success?) && is_digital? && has_digital_key?
  end

  def quantity
    if persisted?
      count
    else
      0
    end
  end

  def reserve!
    return if good.blank?

    if IntegrationModules.enable?(:ecr)
      NomenclatureStockReserver.new(good: good, quantity: count).reserve!
    else
      product.update_attribute :reserve, product.reserve.to_i + count

      good.update_quantity!(-count) unless good.quantity.nil?
    end
  end

  def unreserve!
    return if good.blank?

    if IntegrationModules.enable?(:ecr)
      NomenclatureStockReserver.new(good: good, quantity: count).unreserve!
    else
      product.update_attribute :reserve, product.reserve.to_i - count

      good.update_quantity! count unless good.quantity.nil?
    end
  end

  def coupon_image
    good.try(:coupon_image) || CouponImage.default
  end

  def result_coupon_image_url
    coupon_image.result_image_url digital_key_string
  end

  def has_digital_key?
    digital_key_string.present?
  end

  def has_file?
    is_digital? && !has_digital_key?
  end

  def init_vats
    return self if vat.present?

    if good.present?
      self.purchase_price ||= good.purchase_price
      self.cached_vat ||= good.vat
    end

    unless cached_vat.nil?
      self.vat = VatAmountCalculator.new(vendor).perform(price: total_price, vat: cached_vat)
    end

    self
  end

  def vat_percent
    cached_vat || 0
  end

  def vat_amount
    vat || vendor.zero_money
  end

  def total_vat_price
    vat_amount
  end

  def total_without_vat_price
    total_price - vat_amount
  end

  # The net_amount is the price (for customer) + VAT rate.
  def net_amount
    return price if vat.nil?

    price + vat
  end

  def available_refund_count
    return 0 if order.sale_document.blank?

    quantity - refund_order_items.sum(:quantity)
  end

  private

  def save_digital_key
    digital_key.use! if digital_key.present?
  end
end
