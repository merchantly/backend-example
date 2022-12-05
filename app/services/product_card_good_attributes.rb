class ProductCardGoodAttributes
  def initialize(good)
    @good = good
  end

  def attributes
    good.unique_custom_attributes.each_with_object({}) do |attribute, agg|
      agg[attribute.property_id.to_i] = attribute.value
    end
  end

  private

  attr_reader :good
end
