module ProductUnionPrices
  extend ActiveSupport::Concern

  def price=(_value)
    raise "Can't set price of product union"
  end

  def sale_price=(_value)
    raise "Can't set sale price of product union"
  end

  def price
    nil
  end

  def sale_price
    nil
  end

  # Для индексации и сортировки по цене
  def actual_price
    goods.map(&:actual_price).compact.min
  end

  # private

  # def is_price_unique?
  #   !product_prices.uniq.many?
  # end

  # def product_prices
  #   @product_prices ||= products.alive.map(&:price)
  # end
end
