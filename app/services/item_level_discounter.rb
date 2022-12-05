class ItemLevelDiscounter
  def self.perform(good, price)
    if price.present?
      promotion = PromotionFinder.new(good, price).perform

      if promotion.present?
        OpenStruct.new(promotion_id: promotion.id, discounted_price: promotion.discounted_price(price))
      end
    end
  end
end
