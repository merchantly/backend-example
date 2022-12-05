module CustomAttributes
  extend ActiveSupport::Concern

  included do
    scope :with_property, ->(prop) { by_property_id prop.id }
    scope :by_property_id, ->(id) { where "data ? '#{id}'" }

    # Отлючил чтобы не перегружать базу при сохранении
    # Кода нужно почистить, можно и в ручную запустить
    #
    # before_save :clear_undefined_custom_attributes

    before_save do
      if will_save_change_to_data?
        @custom_files = custom_attributes.select { |a| a.is_a? AttributeFile }
        self.custom_attributes = custom_attributes.compact.map(&:save).compact

        if respond_to?(:cached_all_attributes=)
          self.cached_all_attributes = all_custom_attributes.compact.map(&:to_elastic)
        end

        if respond_to?(:cached_all_in_stock_attributes=)
          self.cached_all_in_stock_attributes = all_custom_attributes(:in_stock).compact.map(&:to_elastic)
        end
      end
      self.data = data.select { |_k, v| !v.nil? && v != '' }
      data_will_change!
      true
    end

    after_save do
      @custom_files.each(&:store!) if @custom_files.present?
    end
  end

  def respond_to_missing?(meth, *args)
    super || meth.to_s =~ /^attr_(.+)=/
  end

  def method_missing(meth, *args)
    case meth.to_s
    when /^attr_(.+)=$/
      data_will_change!
      @custom_attributes = nil

      # Не пойму где и как используется это method_missing, посмотрим.
      #
      Bugsnag.notify StandardError.new('attr_ method missing'), metaData: { meth: meth, id: id, type: self.class.name }

      data[find_property_by_id(Regexp.last_match(1)).id.to_s] = args[0]

    when /^attr_(.+)$/
      data[Regexp.last_match(1).to_s]
    else
      super
    end
  end

  def custom_attribute_by_property(property)
    custom_attributes
      .find { |a| a.property_id == property.id }
  end

  # @param Array[Attribute]
  def custom_attributes=(list)
    # проверяем что id'ы действительно существуют для AttributeDictionary
    exist_list = list.select { |a| !a.is_a?(AttributeDictionary) || vendor.properties.exists?(a.property.id) }.compact

    self.data = exist_list.map(&:as_data).inject({}) { |a, e| a.merge e }

    data_will_change!
    @custom_attributes = exist_list
  end

  # @return Array[Attribute]
  def custom_attributes(force = false)
    @custom_attributes = nil if force
    @undefined_custom_attributes = [] if @custom_attributes.nil?
    @custom_attributes ||= (data || {}).map { |k, v| data_to_attr k, v }.compact
  rescue StandardError => e
    Rails.logger.error e
    Bugsnag.notify e
    []
  end

  def reload(*args)
    @custom_attributes = nil
    super(*args)
  end

  def clear_undefined_custom_attributes
    custom_attributes true
    @undefined_custom_attributes.each do |id|
      data_will_change!
      data.delete id
    end
  end

  def properties
    all_custom_attributes.map(&:property).uniq.compact
  end

  def unsaved_properties
    custom_attributes.map { |a| a.property if a.property_id.present? && a.property_id >= ProductBuilder::NEW_ID }.compact
  end

  def public_custom_attributes
    meth = instance_of?(ProductItem) ? :is_used_in_item : :is_used_in_product
    @public_custom_attributes ||= custom_attributes.select do |a|
      a.valued? && a.property.send(meth) && a.property.alive?
    end
  end

  UnknownPropertyError = Class.new StandardError

  def infucient_custom_attributes
    vendor.properties.alive
          .used_in_products.where
          .not(id: data.keys.map(&:to_i))
          .ordered
          .map(&:build_attribute_by_value)
  end

  def default_custom_attributes
    custom_attributes + infucient_custom_attributes
  end

  # @param Attribute
  #
  def set_attribute(attribute)
    a = attribute.as_data.first
    data[a.first.to_s] = a.second.to_s
    data_will_change!
    @custom_attributes = nil

    attribute
  end

  def set_attribute_by_key(key, value, property_type = nil)
    property = find_or_create_property_by_key(key, property_type)
    set_attribute property.build_attribute_by_string_value value
  end

  def get_attribute_by_key(key)
    property = find_property_by_key(key)
    return nil if property.blank?

    get_attribute_by_property property
  end

  def get_attribute_by_property(property)
    key = property.id.to_s
    return nil unless data.key? key

    property.build_attribute_by_value data[key]
  end

  private

  def data_to_attr(k, v)
    find_property_by_id(k).build_attribute_by_value v
  rescue UnknownPropertyError => e
    Rails.logger.error e
    @undefined_custom_attributes << k
    Bugsnag.notify e
    nil
  end

  def find_or_create_property_by_key(key, property_type = nil)
    raise 'Нет вендора' if vendor_id.blank?

    property_type ||= PropertyDictionary
    dictionary = model_vendor.dictionaries.find_by(key: key) || model_vendor.dictionaries.create!(key: key, custom_title: key)
    model_vendor.properties.find_by(key: key) || property_type.create!(vendor: model_vendor, key: key, custom_title: key, dictionary: dictionary)
  end

  # Этот метод лежит тут, а не глобально, потому что, скорее всего
  # в нем будут использоваться специфичные для конкретной модели свойства
  def find_property_by_id(key)
    raise 'Нет вендора' if vendor_id.blank?

    id = key.to_s.to_i
    @found_properties ||= {}
    @found_properties[id.to_s] ||= model_vendor.properties.find_by(id: id) or raise UnknownPropertyError, key
  end
end
