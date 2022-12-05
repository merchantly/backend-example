class ProductsSpreadsheet < AbstractBaseSpreadsheet
  FIELDS = %w[id article name price sale_price is_sale weight? weight_of_price ms_uuid externalcode description url category category_id categories quantity images position is_published].freeze

  def initialize(vendor, collection)
    @vendor = vendor
    @collection = collection
  end

  private

  attr_reader :vendor

  def encoding
    'utf-8'
  end

  def header_row
    FIELDS.map { |f| Product.human_attribute_name f } + properties.map { |p| "[#{p.name}]" }
  end

  def properties
    @properties ||= vendor.properties.alive.ordered
  end

  def row(product)
    [
      product.id,
      product.article,
      product.title,
      product.price.to_s,
      product.sale_price.to_s,
      product.is_sale,
      product.weight?,
      product.weight_of_price,
      product.ms_uuid,
      product.externalcode,
      product.description,
      product.public_url,
      product.category.try(:title),
      product.category_id,
      product.categories.map(&:name).join(', '),
      product.quantity,
      product.images.map { |i| i.image.url }.join("\n"),
      product.position,
      product.is_published?
    ] + attributes_row(product)
  end

  def attributes_row(product)
    properties.map do |p|
      product.custom_attributes.find { |a| a.property_id == p.id }.try(:readable_value)
    end
  end
end
