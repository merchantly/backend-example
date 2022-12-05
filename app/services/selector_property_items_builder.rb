class SelectorPropertyItemsBuilder
  DEFAULT_COLOR = '#E8E8E8'.freeze

  class SelectorPropertyItem
    include Virtus.model
    attribute :title, String, required: true
    attribute :value, Integer, required: true
    attribute :color, Array, required: true
    attribute :imageUrl, String
    attribute :disabled, Boolean, required: true
  end

  def initialize(property, product)
    @property = property
    @product  = product
  end

  def items
    if property.is_a? PropertyDictionary
      if property.color?
        values.map { |e, disabled| SelectorPropertyItem.new title: e.title, value: e.id, color: "##{e.color.hex}", imageUrl: e.image_url, disabled: disabled }
      else
        values.map { |e, disabled| SelectorPropertyItem.new title: e.title, value: e.id, color: DEFAULT_COLOR, disabled: disabled }
      end
    else
      values.map { |e, disabled| SelectorPropertyItem.new title: "#{property.title}: #{e}", value: e, color: DEFAULT_COLOR, disabled: disabled }
    end
  end

  private

  attr_reader :property, :product

  def attributes
    @attributes ||= build_attributes
  end

  def build_attributes
    product.goods.map do |good|
      good.custom_attributes.map do |custom_attribute|
        { attr: custom_attribute, disabled: !good.is_ordering }
      end
    end.flatten
  end

  def values
    exists = attributes
             .select { |a| a[:attr].property_id == property.id }
             .map do |a|
      if a[:attr].is_a? AttributeDictionary
        [a[:attr].dictionary_entity, a[:disabled]]
      else
        [a[:attr].value, a[:disabled]]
      end
    end

    remove_excess_values(exists)
  end

  def remove_excess_values(attr_values)
    sources = property.values

    result = []

    attr_values.each do |attr_value|
      next unless sources.include? attr_value.first

      result_attr = result.find { |r| r.first == attr_value.first }

      if result_attr.present?
        result_attr[1] = result_attr[1] && attr_value.second
      else
        result << attr_value
      end
    end

    result
  end
end

# Протестировано на товарах:
# http://wannabe.3001.vkontraste.ru/products/4273-minikoltso-poloski-bez-kamney-chernenoe
