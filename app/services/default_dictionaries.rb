class DefaultDictionaries
  ENTITIES = {
    # http://www.kupivip.ru/sizes/woman
    size: %w[XXS XS S M L XL XXL XXXL],
    color: %w[white black red green yellow blue orange brown gray],
    brand: %w[Gucci D&Gi GJ]
  }.freeze

  # Количество свойств создачаемых по-умолчанию
  PROPERTIES_COUNT = ENTITIES.count

  def initialize(vendor)
    @vendor = vendor
  end

  def perform
    build_dictionary Dictionary, :size
    build_dictionary DictionaryColor, :color
    build_dictionary Dictionary, :brand
  end

  private

  attr_reader :vendor

  def build_dictionary(dict_class, key)
    return if vendor.dictionaries.exists?(key: key) ||
      vendor.properties.exists?(key: key)

    dict = dict_class.create! vendor: vendor, key: key, custom_title: t(key, :dictionary)

    ENTITIES[key].each do |name|
      if key == :color
        dict.entities.create! custom_title: I18n.t(name, scope: :colors), color_hex: "##{Color::RGB.by_name(name).hex}"
      else
        dict.entities.create! custom_title: name
      end
    end
    PropertyDictionary
      .create! vendor: vendor,
               dictionary: dict,
               key: dict.key,
               title: t(key, :property),
               is_used_in_item: true,
               is_used_in_product: true
  end

  def t(key, scope)
    raise "Unknown scope #{scope}" unless %i[dictionary property].include? scope

    I18n.t key, scope: [:operator, :names, scope], default: key
  end
end
