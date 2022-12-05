module MoyskladImporting
  class PropertiesUpdater < Updater
    # Тип атрибута | Значение поля type в JSON | Тип поля value в JSON
    # Строка string string
    # Число целое long number
    # Дата time string
    # Справочник {entityType} entityTypeobject **
    # Файл file string
    # Число дробное double number
    # Флажок boolean boolean
    # Текст text string
    # Ссылка link string
    #
    ATTR_TYPES = {
      'customentity' => 'PropertyDictionary',
      'string' => 'PropertyString',
      'text' => 'PropertyText',
      'boolean' => 'PropertyBoolean',
      'long' => 'PropertyLong',
      'link' => 'PropertyLink',
      'double' => 'PropertyDouble',
      'time' => 'PropertyTime',
      'file' => 'PropertyFile'
    }.freeze

    private

    # @return Array[Moysklad::Entities::AttributeMetadata]
    def resource
      @resource ||= build_resource
    end

    def build_resource
      # В докоментации моего склада не сказанно чем одни аттрибуты товаров отличаются от атрибутов
      # групп товаров и вариантов, поэтому грузим у товаров
      # #
      # vendor.moysklad_universe.productfolders.metadata.attrs
      # vendor.moysklad_universe.variant.metadata.attrs
      vendor.moysklad_universe.products.metadata.attrs +
        vendor.moysklad_universe.variants.metadata.characteristics
    end

    def scope(_entity = nil)
      vendor.properties
    end

    def default_attributes(entity, model)
      attrs = super entity, model

      type = ATTR_TYPES[entity.type] || raise("Неизвестный тип аттрибута в МойСклад: #{entity.type} #{entity.to_json}")

      if entity.type == 'customentity'
        dictionary = vendor.dictionaries.by_ms_uuid(entity.customEntityMeta.id).take ||
          raise("Не найден словарь #{entity.customEntityMeta.id} для свойства #{entity.to_json}")
      end

      attrs.merge(
        stock_title: entity.name,
        type: type,
        dictionary_id: dictionary.try(:id),
        is_required: entity.required
        # feature:          entity.feature,
        # position:         entity.position
      )
    end

    def build_model(entity)
      model = build_scope(entity).build

      if entity.is_a? Moysklad::Entities::Characteristic
        model.is_used_in_item = true
        model.is_used_in_product = false

      elsif entity.is_a? Moysklad::Entities::Attribute
        model.is_used_in_product = true
        model.is_used_in_item = false

      elsif entity.is_a? Moysklad::Entities::AttributeMetadata
        model.is_used_in_product = true
        model.is_used_in_item = true
      else
        raise "Не понятно что за каласс атрибута #{entity.class} #{entity.dump}" unless Rails.env.test?
      end

      model
    end
  end
end
