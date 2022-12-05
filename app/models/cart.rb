class Cart < ApplicationRecord
  include Authority::Abilities
  include CurrentVendor
  include TimeScopes
  include OrderCartItems

  upsert_keys %i[vendor_id session_id]

  belongs_to :vendor
  belongs_to :package_good, polymorphic: true

  # Может не быть, если это one-click-buy корзина
  belongs_to :session, primary_key: 'session_id'

  has_many :items, class_name: 'CartItem', dependent: :delete_all

  belongs_to :member

  default_scope { includes(:items) }

  scope :ordered,    -> { order 'id desc' }
  scope :filled,     -> { where 'items_count>0' }
  scope :with_goods, -> { includes(items: [:good]) }

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  validates :coupon_code, length: { maximum: 255 }, allow_blank: true

  delegate :empty?, to: :items

  delegate :discount, to: :discounting

  def self.purge(id)
    find_by(id: id).try :purge
  end

  def purge
    if session_id.present? && session.blank?
      destroy
      return
    end

    return if items_count.positive?

    if items.any?
      Cart.reset_counters id, :items
      nil
    else
      destroy
    end
  end

  def title
    I18n.t('activerecord.models.cart', id: id)
  end

  def has_unorderable_items?
    !all_ordering?
  end

  def all_ordering?
    items.all?(&:is_ordering)
  end

  def cookie
    return to_global_id.to_param if session_id.blank?
  end

  def package_item
    CartItem.new good: package_good, count: package_count, cart: self if package_good.present?
  end

  def package_good_global_id
    package_good.try :global_id
  end

  def package_good_global_id=(gid)
    if gid.present?
      self.package_good = vendor.locate_package(gid)
    else
      self.package_good = nil
    end
  end

  def items_amount
    items.count
  end

  def discounting
    raise 'no coupon for discounting' if coupon.blank?

    @discounting ||= coupon.discounter(items: items, package_good: package_good, package_count: package_count).perform
  end

  def discount_price
    return vendor.zero_money if coupon.blank?

    discounting.discount_price
  end

  def total_discounted
    return total_price if coupon.blank?

    discounting.total_discounted
  end

  def discount_info
    return nil if coupon.blank?

    discounting.info
  end

  def coupon
    return nil if coupon_code.blank?

    @coupon ||= vendor.coupons.by_code coupon_code
  end

  def coupon_code
    super.presence
  end

  def total_price
    if coupon.present?
      total_discounted
    else
      products_with_package_price
    end
  end

  def total_with_delivery_price
    products_with_package_price + delivery_price
  end

  def products_with_package_price
    products_price + package_price
  end

  def products_price
    items.map(&:total_price).compact.inject(:+) || vendor.zero_money
  end

  def package_price
    package_good.present? ? (package_good.price * package_count) : vendor.zero_money
  end

  def delivery_price
    delivery_type.try(:price) || vendor.zero_money
  end

  def delivery_type
    vendor.default_delivery_type
  end

  def clean!
    items.delete_all
  end

  def not_empty
    !empty?
  end

  def as_json(conf = nil)
    if conf.nil?
      conf = {
        only: %i[id session_id created_at updated_at coupon_code remote_ip],
        include: [:items]
      }
    end
    super conf
  end

  def has_good?(good)
    items.by_good(good).exists?
  end

  def add_good(good, count = 1, product_price:, weight: nil, change_exist_count: false, promotion: nil)
    transaction do
      item = items.by_good(good).first
      if item.present?
        if change_exist_count
          item.update_count count, weight
        else
          item.increment_count count, weight
        end
      else
        items.create! good: good, count: count, weight: weight, product_price: product_price, promotion: promotion
      end
    end
  end

  def remove_good(good)
    remove_item items.by_good(good).take
  end

  def update_good(product_price:, good: nil, count: 1, weight: nil)
    transaction do
      item = items.by_good(good).first
      if item.present?
        if weight.present?
          item.update_attribute :weight, weight
        else
          item.update_attribute :count, count
        end
        item
      else
        items.create! good: good, count: count, weight: weight, product_price: product_price
      end
    end
  end

  def remove_item(item)
    return unless item

    items.destroy item
    reload
  end

  def update_cart_from_params(cart_params)
    return if cart_params.blank?

    attrs = cart_params.except('items')

    if attrs['package_good_global_id'].blank? || attrs['package_count'].blank?
      attrs['package_good_global_id'] = nil
      attrs['package_count'] = 0
    end

    cart_params['items'] ||= []
    # удаляем если в кол-во ввели пустоту или 0
    cart_items = cart_params['items'].reject do |id, cart_item|
      zero_amount = (
        (!cart_item['weight'].nil? && cart_item['weight'].to_f.zero?) ||
        (!cart_item['count'].nil? && cart_item['count'].to_f.zero?)
      )
      remove_item items.find(id) if zero_amount
      zero_amount
    end

    attrs['items_attributes'] = cart_items.map do |id, cart_item_attrs|
      cart_item_attrs.dup.merge id: id
    end.compact

    update attrs
  end

  def total_vat_price
    if coupon.present?
      discounting.total_vat_price
    else
      (items.map(&:total_vat_price).compact.inject(:+) || vendor.zero_money) + package_vat_price
    end
  end

  def total_without_vat_price
    return total_price unless total_vat_price.to_f.positive?

    if VatAmountCalculator.vat_inclusive?(vendor)
      total_price - total_vat_price
    else
      total_price
    end
  end

  def package_vat_price
    if package_good.present?
      VatAmountCalculator.new(vendor).perform(price: package_price, vat: package_good.try(:vat))
    else
      vendor.zero_money
    end
  end

  def add_allowance!(attrs)
    coupon = Allowance.create!(attrs)

    update coupon_code: coupon.code
  end

  def remove_allowance!
    coupon.archive!

    update coupon_code: nil
  end
end
