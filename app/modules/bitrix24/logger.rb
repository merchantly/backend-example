module Bitrix24
  class Logger
    include Virtus.model strict: true
    include AutoLogger

    attribute :vendor_bitrix24, VendorBitrix24

    def info(str)
      logger.info str
      vendor_bitrix24.add_log "info: #{str}"
    end

    def error(str)
      logger.error str
      vendor_bitrix24.add_log "error: #{str}"
    end
  end
end
