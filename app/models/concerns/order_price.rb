module OrderPrice
  extend ActiveSupport::Concern

  included do
    # Устанавливаем цены только при сохранении
    # чтобы потом случано их не изменить при редактировании
    before_validation :setup_prices, on: :create

    %i[products total total_with_delivery discount payment_discount package total_without_vat].each do |price|
      monetize "#{price}_price_cents", as: "#{price}_price",
                                       with_model_currency: "#{price}_price_currency",
                                       allow_nil: false,
                                       numericality: {
                                         greater_than_or_equal_to: 0,
                                         less_than: Settings.maximal_money
                                       }
    end
    %i[delivery custom_delivery].each do |price|
      monetize "#{price}_price_cents", as: "#{price}_price",
                                       with_model_currency: "#{price}_price_currency",
                                       allow_nil: true,
                                       numericality: {
                                         allow_nil: true,
                                         greater_than_or_equal_to: 0,
                                         less_than: Settings.maximal_money
                                       }
    end

    monetize :total_sale_amount_cents, as: :total_sale_amount,
                                       with_model_currency: :total_sale_amount_currency,
                                       allow_nil: false,
                                       numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money, allow_nil: true }

    monetize :total_vat_cents, as: :total_vat, allow_nil: true
  end

  alias_attribute :total_price, :products_price

  def update_prices!
    setup_prices
    save!
  end

  def setup_prices
    self.products_price = calculated_products_price
    self.package_price  = calculated_package_price
    self.total_price    = calculated_total_price
    self.delivery_price = custom_delivery_price || calculated_delivery_price

    self.free_delivery_threshold = calculated_free_delivery_threshold

    self.total_with_delivery_price = total_price + (delivery_price.nil? ? 0 : delivery_price)
    self.total_refund_amount = vendor.zero_money

    setup_vats if Settings.vat_required && IntegrationModules.enable?(:ecr)

    self.total_without_vat_price = total_vat.to_f.positive? ? (total_price - total_vat) : total_price

    setup_discount_price
  end

  def order_prices
    @order_prices ||= OrderDiscountedPricesBuilder.new(order: self).perform
  end

  private

  def discounting
    raise 'no coupon for discounting' if coupon.blank?

    @discounting ||= discounter.perform
  end

  def discounter
    @discounter ||= coupon.discounter(items: items.map(&:init_vats), package_good: package_good, package_count: package_count)
  end

  def calculated_total_price
    price = if coupon.present?
              discounting.total_discounted.exchange_to(currency)
            else
              products_with_package_price
            end

    payment_discounting = PaymentDiscounter.new(order: self, total_price: price).perform

    if payment_discounting.present?
      setup_payment_discount_price(payment_discounting)

      payment_discounting.total_discounted
    else
      price
    end
  end

  def setup_discount_price
    if coupon.present?
      self.discount       = discounting.discount
      self.discount_price = discounting.discount_price.exchange_to(currency)
    else
      self.discount = 0
      self.discount_price = zero_money
    end

    self.total_sale_amount = calculated_total_sale_amount
  end

  def setup_payment_discount_price(discounting)
    self.payment_discount = discounting.discount
    self.payment_discount_price = discounting.discount_price.exchange_to(currency)
  end

  def calculated_total_sale_amount
    items.map(&:total_sale_amount).inject(:+).try :exchange_to, currency
  end

  def products_with_package_price
    products_price + package_price
  end

  def calculated_products_price
    (items.map(&:total_price).inject(:+) || zero_money).exchange_to currency
  end

  def calculated_package_price
    (package_good.present? ? (package_good.price * package_count) : zero_money).exchange_to currency
  end

  def update_vats!
    setup_vats
    save!
  end

  def setup_vats
    return if items.blank?

    if coupon.present?
      self.total_vat = discounting.total_vat_price.exchange_to(currency)
    else
      self.total_vat = (Money.new(items.map(&:init_vats).sum(&:vat_cents), currency) + package_vat_price).exchange_to(currency)
    end
  end

  def package_vat_price
    return zero_money if package_price.to_f.zero?

    VatAmountCalculator.new(vendor).perform(price: price, vat: p.vat)
  end
end
