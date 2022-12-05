class ProductCardPropertiesBuilder
  # У нас есть два варианта карточки товара:
  # 1. Когда выбор идет между вариантами товара.
  # 2. Когда выбор идет по характеристикам.

  class SelectorProperty
    include Virtus.model
    attribute :id,    Integer, required: true
    attribute :title, String, required: true
    attribute :type,  String, required: true
    attribute :items, Array
  end

  def initialize(product)
    @product = product
  end

  def properties
    props = build_properties

    # Если товар это просто Product и имеет items (классический товар из moysklad)
    # и у него всего одно свойство, то его проще выбирать вариантами.
    # Для этого мы в карточку отдаем properties = []
    #
    if props.count == 1 and !product.is_union?
      []
    else
      props
    end
  end

  private

  attr_reader :product

  def build_properties
    product.unique_properties.map do |prop|
      build_selectable_property prop
    end
  end

  def build_selectable_property(prop)
    type = prop.color? ? :colors : :items
    items = SelectorPropertyItemsBuilder
            .new(prop, product)
            .items
    SelectorProperty.new id: prop.id, title: prop.title, type: type, items: items
  end
end
