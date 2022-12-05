module MoyskladImporting
  class VendorLogger
    FLUSH_PERIOD = 15.seconds
    attr_reader :log_entity

    include Virtus.model
    attribute :vendor, ::Vendor
    # attribute :error_stock_tos, Array[Moysklad::Entities::StockTO], default: []
    # attribute :updated_product_items, Array[ProductItem], default: []
    attribute :products_to_clean_count, Integer, default: 0
    attribute :synced_at, Time
    attribute :last_flushed_at, Time, default: Time.zone.now
    #-> { Time.zone.now }
    #

    delegate :add_log_record, :update_data!, to: :log_entity, allow_nil: true

    def initialize(*args)
      super(*args)
      self.last_flushed_at = Time.zone.now
    end

    def create!
      ids = vendor.stock_importing_log_entities.started.ordered.pluck(:id)
      @log_entity = vendor.stock_importing_log_entities.create!

      raise AlreadySyncing, ids.join(', ') if ids.present?

      debug 'Старт'
    end

    def warn(text)
      log :warn, text
    end

    def error(text)
      log :error, text
    end

    def fatal_error(text)
      @fatal_error = text
      error text
    end

    def info(text)
      log :info, text
    end

    def debug(text)
      log :debug, text
    end

    def finish!
      debug 'Финиш'
      if log_entity.present?
        flush!
        log_entity.finish! !@fatal_error
      end
    end

    def flush!
      raise NoLogEntity unless log_entity

      # @log_entity.update_attributes! stats: result, log: @log.join("\n")
      self.last_flushed_at = Time.zone.now
    end

    private

    attr_reader :vendor

    def result
      StockImportingStats.new(
        # updated_items_count:   updated_product_items.count,
        new_items_count: vendor.product_items.where('product_items.created_at>?', synced_at).count,
        error_items_count: error_stock_tos.count
      )
    end

    def log_global(serv, message)
      message = { message: message } unless message.is_a? Hash
      MoyskladImporting.logger.send(serv, message.merge(vendor_id: vendor.id))
    end

    def log(serv, message)
      log_global serv, message

      if message.is_a? Hash
        message = (message[:message]).to_s # {message[:entity].try(:class)} #{message[:entity].try(:uuid)} #{message[:entity].try(:name)}"
      end
      add_log_record "[#{serv}] #{Time.zone.now} #{message}"
      flush! if flushed_long_time_ago?
    end

    def flushed_long_time_ago?
      Time.zone.now - last_flushed_at > FLUSH_PERIOD
    end
  end
end
