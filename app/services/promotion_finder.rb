class PromotionFinder
  def initialize(good, price)
    @good = good || raise('No good')
    @price = price || raise('No price')
  end

  def perform
    return unless promotions.exists?

    promotions
      .select { |promotion| promotion.satisfy_product_behavior?(product) && promotion.satisfy_category_behavior?(product) }
      .min_by { |promotion| promotion.discounted_price(price) }
  end

  private

  attr_reader :price, :good

  delegate :vendor, to: :good

  def product
    @product ||= good.is_a?(Product) ? good : good.product
  end

  def promotions
    vendor.promotions.active
  end
end
