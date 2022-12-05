require 'securerandom'

class Coupon < ApplicationRecord
  attr_accessor :digest_max

  include Authority::Abilities
  include Archivable
  extend Enumerize
  include PgSearch::Model

  strip_attributes

  USE_BEHAVIOR_INCLUDE = 'include'.freeze
  USE_BEHAVIOR_EXCLUDE = 'exclude'.freeze
  USE_BEHAVIORS = [USE_BEHAVIOR_EXCLUDE, USE_BEHAVIOR_INCLUDE].freeze

  monetize :minimal_order_total_price_cents, allow_nil: true

  belongs_to :vendor
  has_many :orders

  has_many :categories_coupons, dependent: :destroy
  has_many :categories, through: :categories_coupons

  has_many :coupons_products, dependent: :destroy
  has_many :products, through: :coupons_products

  pg_search_scope :search_by_code, against: :code, using: %i[tsearch trigram]

  scope :base, -> { where type: %w[CouponSingle CouponGroup] }
  scope :by_state, lambda { |state|
    state = 'alive' if state.blank?
    case state
    when 'alive'
      alive
    when 'archive'
      archive
    else
      raise "Unknown state: #{state}"
    end
  }

  scope :active, -> { alive.enabled.where('start_at < ? OR start_at IS NULL', Time.zone.now).where('expires_at > ? OR expires_at IS NULL', Time.zone.now) }
  scope :enabled, -> { where is_enabled: true }
  scope :used,    -> { where 'used_count > 0' }
  scope :usable,  -> { enabled.where(type: %w[CouponSingle CouponPiece Promotion]).where('use_count > 0 OR use_count IS NULL') }
  scope :ordered, -> { order created_at: :desc }

  enumerize :discount_type, in: %w[percent fixed], default: 'percent'
  enumerize :use_products_behavior, in: USE_BEHAVIORS, default: USE_BEHAVIOR_EXCLUDE
  enumerize :use_categories_behavior, in: USE_BEHAVIORS, default: USE_BEHAVIOR_EXCLUDE

  before_validation :generate_code, unless: :code
  before_validation :upcase_code
  before_validation :set_type
  before_save :validate_type

  validates :code,
            presence: true,
            uniqueness: { scope: :vendor_id }

  validate :expires_at_in_future, on: :create

  def self.by_code(code)
    find_by(code: code.to_s.upcase)
  end

  def discount_price
    discount.to_money(vendor.default_currency) if discount_type.fixed?
  end

  def discounter(items:, package_good:, package_count:)
    discounter_class.new(coupon: self, items: items, package_good: package_good, package_count: package_count)
  end

  def for_all?
    categories.empty? && products.empty?
  end

  def to_label
    to_s
  end

  def uses_count
    used_count + use_count
  end

  def to_s
    code
  end

  def used?
    !use_count.nil? && !use_count.positive?
  end

  def active?
    alive? && actual? && !used?
  end

  def fixed_discount
    Money.new(discount * vendor.default_currency.subunit_to_unit, vendor.default_currency)
  end

  def actual?
    is_enabled? && !expired?
  end

  def expired?
    # Сколько еще раз можно использовать
    (use_count.present? && use_count.zero?) || timed_out? || archived?
  end

  def validate_call_error
    validate_call!
    ''
  rescue Coupon::Error => e
    e.message
  end

  def validate_call!(items_count:, is_first_client_order:, is_address_used:, total_price:)
    raise(Expired, code) unless alive? && !expired?

    # проверяем кол-во товаров в корзине если в купоне стоит условие применения по кол-ву
    if minimal_products_count.present? && items_count < minimal_products_count
      raise MinimalProductsCountCouponError.new(code, minimal_products_count)
    end

    if minimal_order_total_price.present? && (minimal_order_total_price.exchange_to(total_price.currency) > total_price)
      raise MinimalOrderTotalPriceCouponError.new(code, minimal_order_total_price)
    end

    # не применяем купон если он предназначен только для первой покупки
    if only_first_order?
      # проверяем можно ли использовать купон
      # для первой покупки
      raise NotFirstOrderCouponError, code unless is_first_client_order
      raise NotFirstOrderCouponError, code if is_check_address? && is_address_used
    end
  end

  def call!(items_count:, is_first_client_order:, is_address_used:, total_price:)
    validate_call!(
      items_count: items_count,
      is_first_client_order: is_first_client_order,
      is_address_used: is_address_used,
      total_price: total_price
    )

    use!
  end

  def use!
    with_lock do
      counters = { used_count: 1 }
      counters[:use_count] = -1 unless use_count.nil?

      self.class.update_counters id, counters
      on_call
      reload

      archive! if expired?
    end
  end

  def product_ids
    return [] if super.blank?

    product_union_ids = Product.where(product_union_id: super).pluck(:id)

    (super + product_union_ids).uniq
  end

  def satisfy_product_behavior?(product)
    return true if product_ids.empty?

    overlap = product_ids.include? product.id

    case use_products_behavior
    when Coupon::USE_BEHAVIOR_INCLUDE
      overlap
    when Coupon::USE_BEHAVIOR_EXCLUDE
      !overlap
    else
      raise "Unknown #{use_products_behavior}"
    end
  end

  def satisfy_category_behavior?(product)
    return true if category_ids.empty?

    overlap = category_ids & product.categories.map(&:path_ids).flatten

    case use_categories_behavior
    when Coupon::USE_BEHAVIOR_INCLUDE
      overlap.any?
    when Coupon::USE_BEHAVIOR_EXCLUDE
      overlap.none?
    else
      raise "Unknown #{use_categories_behavior}"
    end
  end

  def level
    if product_ids.present? || category_ids.present?
      :item
    else
      :cart
    end
  end

  private

  def discounter_class
    if discount_type.fixed?
      Discounter::Fixed
    else
      Discounter::Percent
    end
  end

  def on_call
    # do nothing
  end

  def validate_type
    raise 'Купон должен быть STI' if instance_of?(Coupon)
  end

  def timed_out?
    (expires_at? && (expires_at < Time.zone.now)) || (start_at? && (start_at > Time.zone.now))
  end

  def generate_code
    self.code = SecureRandom.hex(digest_max || 3)
  end

  def upcase_code
    code.try :upcase!
  end

  def set_type
    self.type = self.class.name unless type?
  end

  def expires_at_in_future
    errors.add :expires_at, I18n.t('errors.coupon.expires_at_in_past') if timed_out?
  end
end

class Coupon::Error < StandardError
  def initialize(code)
    @code = code
  end
end

class Coupon::NotFound < Coupon::Error
  def message
    I18n.vt('errors.coupon.not_found', code: @code)
  end
end

class Coupon::Expired < Coupon::Error
  def message
    I18n.vt('errors.coupon.expired', code: @code)
  end
end

class Coupon::MinimalProductsCountCouponError < Coupon::Error
  def initialize(coupon_code, items_count)
    @coupon_code = coupon_code
    @items_count = items_count
  end

  def message
    I18n.t('errors.order.minimal_products_count', coupon_code: @coupon_code, count: @items_count)
  end
end

class Coupon::MinimalOrderTotalPriceCouponError < Coupon::Error
  include MoneyRails::ActionViewExtension
  include MoneyHelper

  def initialize(coupon_code, total_price)
    @coupon_code = coupon_code
    @total_price = humanized_money_with_currency(total_price)
  end

  def message
    I18n.t('errors.order.minimal_order_total_price_coupon', coupon_code: @coupon_code, total_price: @total_price)
  end
end

class Coupon::NotFirstOrderCouponError < Coupon::Error
  def message
    I18n.t('errors.order.not_first_order_coupon', coupon_code: @code)
  end
end
