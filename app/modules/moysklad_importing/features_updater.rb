module MoyskladImporting
  class FeaturesUpdater < Updater
    include BuilderCustomAttributes

    private

    def resource
      @resource ||= vendor.moysklad_universe.variants.all expand: :product
    end

    def scope(entity = nil)
      if entity.present?
        product = vendor.products.by_ms_uuid(entity.product.id).take
        if product.blank?
          raise MoyskladImporting::Errors::NoRelationFound.new(entity, entity.product.id, :good)
        end

        product.items
      else
        vendor.product_items
      end
    end

    def default_attributes(feature_entity, model)
      attrs = {
        custom_attributes: build_custom_attributes_for_variant(feature_entity),
        is_archived: feature_entity.archived,
        code: feature_entity.code.presence
      }

      if model.quantity.nil? # TODO сделать опциональной настройкой
        attrs.merge!(
          quantity: 0,
          stock: 0,
          reserve: 0
        )
      end
      super.merge attrs
    end
  end
end
