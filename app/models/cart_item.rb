# не используем ActiveRecord callbacks
# см. models/cart.rb метод clean!

class CartItem < ApplicationRecord
  include GoodItem

  attr_accessor :vendor_id # Костыль для factories

  belongs_to :cart, counter_cache: :items_count, touch: true
  belongs_to :product_price

  belongs_to :promotion

  delegate :actual_price, :title, :description, :selling_by_weight?, :weight_of_price, to: :good
  delegate :selling_by_weight?, :weight_of_price, to: :product

  validates :good, presence: true
  validates :weight, numericality: { greater_than: 0, allow_blank: true }
  validates :count, numericality: { greater_than: 0, less_than: MAX_INTEGER }

  scope :empty_weight, -> { where weight: nil }

  monetize :stored_price_cents, as: :stored_price,
                                with_model_currency: :stored_price_currency,
                                allow_nil: false,
                                numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  delegate :vendor, to: :cart

  before_validation do
    self.stored_price = price
  end

  def price
    # default and sale price may change due to the good sale
    # other prices do not depend on good sale
    good_price = if product_price.blank? || product_price.is_default_or_sale?
                  good.actual_price
                 else
                  product_price.price
                 end

    return good_price if promotion.blank?

    promotion.discounted_price(good_price)
  end

  def sale_amount
    return vendor.zero_money if !product_price.sale? || good.blank? || good.sale_price.nil?

    good.price - good.sale_price
  end

  def total_sale_amount
    if selling_by_weight?
      sale_amount * count.to_f * item_weight.to_f / weight_of_price
    else
      sale_amount * count
    end
  end

  def increment_count(count, weight)
    if selling_by_weight?
      if weight.present?
        new_weight = self.weight + weight.to_f
      else
        new_weight = self.weight + (self.weight * count.to_i)
      end
      update_attribute :weight, new_weight
    else
      increment! :count, count.to_i
    end

    self
  end

  def update_count(count, weight)
    if selling_by_weight?
      if weight.present?
        new_weight = weight.to_f
      else
        new_weight = self.weight * count.to_i
      end
      update_attribute :weight, new_weight
    else
      update_attribute :count, count.to_i
    end

    self
  end

  def quantity
    if persisted?
      count
    else
      0
    end
  end

  def to_s
    "#{good.title} #{count} шт."
  end

  def title
    good.long_title
  end

  def is_ordering
    return false if good.blank?

    good.is_ordering && good.orderable_quantity?(count)
  end

  def vat_percent
    good.vat || 0
  end

  def vat_amount
    total_vat_price || vendor.zero_money
  end

  def total_vat_price
    return Money.new(0, price.try(:currency) || vendor.currency_iso_code) if good.vat.blank?

    VatAmountCalculator.new(vendor).perform(price: total_price, vat: vat_percent)
  end

  def total_without_vat_price
    if VatAmountCalculator.vat_inclusive?(vendor)
      total_price - total_vat_price
    else
      total_price
    end
  end
end
