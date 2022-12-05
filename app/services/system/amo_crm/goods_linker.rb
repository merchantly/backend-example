module System::AmoCRM
  class GoodsLinker < Base
    include Virtus.model strict: true

    attribute :order, Order
    attribute :lead_id, Integer
    attribute :catalog_id, Integer

    def perform
      amocrm.client.post 'links/set', request: { links: { link: links } }
    end

    private

    delegate :vendor, to: :order

    def links
      order.items.map do |item|
        if item.product.amocrm_catalog_element_id.nil?
          binding.debug_error
          System::AmoCRM::ExportProducts.new(vendor: vendor, products: [item.product]).perform
          item.product.reload
        end

        {
          from: :leads,
          from_id: lead_id,
          to: :catalog_elements,
          to_id: item.product.amocrm_catalog_element_id,
          to_catalog_id: catalog_id,
          quantity: item.count
        }
      end
    end
  end
end
