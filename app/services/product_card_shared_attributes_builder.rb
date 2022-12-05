class ProductCardSharedAttributesBuilder
  def initialize(product)
    @product = product
  end

  def attributes
    product
      .shared_custom_attributes
      .select(&:valued?)
  end

  private

  attr_reader :product
end
