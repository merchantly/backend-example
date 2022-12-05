module MoyskladImporting
  class GoodFoldersUpdater < Updater
    private

    def remains_scope
      # пока вообще никого не удаляем, пусть в ручную удаляют
      super.where(id: nil)

      # super.alive.has_stock_linked
    end

    def archive_all_remains
      remains_scope.each(&:alone_archive!)
    end

    def resource
      @resource ||= vendor.moysklad_universe.productfolders.all expand: :productFolder
    end

    def find_model(entity)
      super || find_category_by_name(entity.name)
    end

    def find_category_by_name(name)
      vendor.categories.not_linked.by_name(name).first
    end

    def scope(_good_folder_entity = nil)
      vendor.categories
    end

    def default_attributes(entity, model)
      attrs = super(entity, model)

      attrs[:stock_title] = entity.name
      attrs[:stock_description] = entity.description

      if entity.productFolder.present? && vendor.moysklad_mirror_categories_tree?
        externalCode = entity.productFolder.externalCode
        if externalCode.present?
          parent = vendor.categories.by_externalcode(entity.productFolder.externalCode).first
          if parent.present?
            attrs[:parent] = parent
          else
            Bugsnag.notify 'Parent is not found', metaData: { entity: entity.dump, vendor_id: vendor.id }
          end
        else
          Bugsnag.notify 'No externalCode for parent productFolder', metaData: { entity: entity.dump, vendor_id: vendor.id }
        end
      end

      attrs
    end

    def build_model(_entity)
      vendor.categories.build
    end
  end
end
