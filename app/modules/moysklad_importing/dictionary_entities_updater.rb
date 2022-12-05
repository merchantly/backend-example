module MoyskladImporting
  class DictionaryEntitiesUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.all_custom_entities
    end

    def scope(custom_entity = nil)
      if custom_entity.present?

        dictionary = vendor.dictionaries.by_ms_uuid(custom_entity.entityMetadataUuid).take
        raise MoyskladImporting::Errors::NoRelationFound.new(custom_entity, custom_entity.entityMetadataUuid) if dictionary.blank?

        dictionary.entities

      else

        # Это запрашивают полны scope для архивирования
        vendor.dictionary_entities
      end
    end

    def default_attributes(entity, model)
      attrs = super entity, model

      attrs.merge(
        stock_title: entity.name,
        stock_description: entity.description
      )
    end
  end
end
