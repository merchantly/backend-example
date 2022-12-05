require 'ostruct'

module ProductCustomAttributes
  def good_custom_attributes
    custom_attributes
  end

  # all_custom_attributes = shared_custom_attributes + unique_custom_attributes
  #
  def unique_properties
    @unique_properties ||= unique_custom_attributes
                            .map(&:property)
                            .uniq
                            .compact
  end

  def unique_custom_attributes
    if is_part_of_union?
      props = product_union.unique_properties.map(&:id)
      custom_attributes
        .select { |a| props.include? a.property_id }
    else
      goods_count = alive_goods.count
      # goods_count = ordering_goods.count

      # Тут должно быть именно меньше количество goods_count. Потому что мы выбираем уникальные
      # атрибуты, то есть аттрибуты которые встречаются НЕ во всех вариантах товара
      # Пример такого товара: http://motivation-shop.ru/products/konstruktory-pumping-block
      goods_custom_attributes
        .select { |_k, v| v.count < goods_count }
        .values
        .map(&:attr)
        .sort_by { |attribute| attribute.property.position_in_product }
    end
  end

  def shared_custom_attributes
    @shared_custom_attributes ||= build_shared_custom_attributes
  end

  def all_custom_attributes(scope = nil)
    aggregated_custom_attributes(scope)
      .values
      .map(&:attr)
      .sort_by { |attribute| attribute.property.position_in_product }
  end

  private

  def build_shared_custom_attributes
    goods_count = goods.count

    # Нет смысл брать свойства только в заказываемых orders
    # потому что в этом случае свойства, которые есть только у одного продаваемого варианта
    # в карточке товара будет считаться как общий для всех вариантов аттрибут
    # https://www.pivotaltracker.com/story/show/108950180
    #
    # goods_count = ordering_goods.count

    shared_attributes = goods_custom_attributes
                        .select { |_k, v| v[:count] == goods_count }
                        .values
                        .map(&:attr)

    (good_custom_attributes + shared_attributes).uniq.sort_by { |attribute| attribute.property.position_in_product }
  end

  # Аттрибуты всех вариантов и самого товара
  # TODO Кешировать в модели товара
  def aggregated_custom_attributes(scope = nil)
    custom_attributes_collection(goods_include_me(scope))
  end

  def alive_goods
    goods.select(&:alive?)
  end

  # Аттрибуты всех вариантов исключая самого товара
  # TODO Кешировать в модели товара
  def goods_custom_attributes
    # custom_attributes_collection goods.select(&:is_ordering)
    # выбираем из всех живых товаров, а не только заказываемые

    # изначально так и было(select(&:is_ordering)) и это было проблемой
    # вот конкретно где проблема https://github.com/BrandyMint/merchantly/blob/78effed1ca76a3fa4f0a3cd6362adc889a1bf558/app/models/concerns/product_custom_attributes.rb#L55
    # мы сравниваем кол-во всех живых товаров с кол-вом заказываемых товаров,
    # и если в товара один good кончился то общие свойства неправильно высчитываются.
    # как я говорил ранее - этот код очень запутан и непонятен

    custom_attributes_collection alive_goods
  end

  def custom_attributes_collection(list)
    list
      .map(&:good_custom_attributes)
      .flatten
      .each_with_object({}) do |attr, agg|
      key = attr.to_hash
      agg[key] ||= OpenStruct.new attr: attr, count: 0
      agg[key].count += 1
    end
  end
end
