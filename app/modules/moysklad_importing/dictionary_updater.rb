module MoyskladImporting
  class DictionaryUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.company_settings_metadata.customEntities
    end

    def scope(_entity = nil)
      vendor.dictionaries
    end

    def default_attributes(entity, model)
      attrs = super entity, model
      attrs.merge stock_title: entity.name
    end
  end
end
