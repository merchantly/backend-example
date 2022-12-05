# Базовый класс генератора xml для экспорта

module Export
  class BaseExportYml
    include RoutesConcern

    DATE_FORMAT = '%Y-%m-%d %H:%M'.freeze # YYYY-MM-DD hh:mm

    attr_reader :vendor

    def initialize(vendor)
      @vendor = vendor
    end

    private

    def delivery_has_pickup?
      vendor.vendor_deliveries.alive.by_type(OrderDeliveryPickup).any?
    end

    def has_delivery?
      vendor.vendor_deliveries.any?
    end

    def products
      vendor.products.common.published.orderable
    end
  end
end
