module MoyskladImporting
  class GroupsUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.groups.all
    end

    def scope(_entity = nil)
      vendor.vendor_groups
    end

    def default_attributes(entity, model)
      attrs = super entity, model

      attrs.merge(
        name: entity.name
      )
    end
  end
end
