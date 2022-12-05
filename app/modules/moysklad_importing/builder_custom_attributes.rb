module MoyskladImporting
  module BuilderCustomAttributes
    private

    # @param Moysklad::Entities::Product
    def build_custom_attributes_for_product(entity)
      # У Service и Bundler нет attrs
      return unless entity.respond_to? :attrs
      return unless entity.attrs

      entity.attrs.map do |ms_attribute|
        property = vendor.properties.by_ms_uuid(ms_attribute.meta.id).take or
          raise MoyskladImporting::Errors::NoRelationFound.new(ms_attribute, ms_attribute.meta)

        property
          .attribute_class
          .build_from_ms_attribute property: property, ms_attribute: ms_attribute
      end
    end

    def build_custom_attributes_for_variant(entity)
      # У Service и Bundler нет characteristics
      return unless entity.respond_to? :characteristics
      return unless entity.characteristics

      entity.characteristics.map do |ms_characteristic|
        property = vendor.properties.by_ms_uuid(ms_characteristic.meta.id).take or
          raise MoyskladImporting::Errors::NoRelationFound.new(ms_characteristic, ms_characteristic.meta)

        property
          .attribute_class
          .build_from_ms_attribute property: property, ms_attribute: ms_characteristic
      end
    end
  end
end
