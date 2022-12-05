module MoyskladImporting
  class Universe
    include Virtus.model

    attribute :vendor,         Vendor
    attribute :vendor_logger,  VendorLogger
    attribute :synced_at,      Time
  end
end
