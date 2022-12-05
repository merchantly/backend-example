module System::AmoCRM
  class ExportProducts < Base
    include Virtus.model strict: true

    attribute :vendor, Vendor
    attribute :catalog_id, Integer
    attribute :moysklad_custom_field_id, Integer
    attribute :products

    # Удалить все, начиная с 826533

    def perform
      return if catalog_elements.empty?

      result = amocrm.client.post 'catalog_elements/set', request: {
        catalog_elements: {
          add: catalog_elements
        }
      }

      result.catalog_elements.add.catalog_elements.each do |element|
        ms_uuid = element.custom_fields.find { |cf| cf.id.to_i == moysklad_custom_field_id }[:values].first[:value]
        vendor.products.where(ms_uuid: ms_uuid).update_all amocrm_catalog_element_id: element.id
      end

      result.catalog_elements.count
    end

    private

    attr_accessor :goods

    def catalog_elements
      @catalog_elements ||= products
        .select { |p| p.amocrm_catalog_element_id.nil? }
        .map do |p|
          {
            name: p.title,
            catalog_id: catalog_id,
            custom_fields: custom_fields(p)
          }
      end
    end

    def custom_fields(product)
      [
        { id: moysklad_custom_field_id, values: [{ value: product.ms_uuid }] },
        # TODO артикул, количество, цена
        # { id: vendor.vendor_amocrm.goods_catalog_moysklad_custom_field_id, values: [{value: product.ms_uuid}] }
      ]
    end
  end
end
