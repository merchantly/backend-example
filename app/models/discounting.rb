class Discounting
  include MoneyHelper
  include Virtus.model struct: true

  attribute :discount,         Decimal
  attribute :discount_price,   Money # Общая cумма скидки. Сохраняется в Order#discount_price
  attribute :total_discounted, Money
  attribute :total_vat_price, Money
  attribute :free_delivery, Boolean

  def info
    I18n.t(
      'activerecord.models.attributes.cart.discount_info',
      discount: discount,
      discount_price: humanized_money_with_currency(discount_price)
    )
  end
end
