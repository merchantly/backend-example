module MoyskladImporting
  class WarehouseUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.stores.all
    end

    def scope(_entity = nil)
      vendor.moysklad_warehouses
    end

    def default_attributes(entity, _model)
      super.merge(
        ms_stockstore_uri: entity.meta.href,
        name: entity.name,
        externalcode: entity.externalCode
      )
    end
  end
end
