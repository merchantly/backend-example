module MoyskladImporting
  class Processor
    SILENT_ERRORS = [Faraday::ConnectionFailed, Moysklad::Client::Error, Net::ReadTimeout].freeze

    # Ожидание между запросами
    REQUEST_TIMEOUT = 0.3

    def self.build(vendor)
      new vendor: vendor
    end

    def initialize(vendor:, worker: nil, scheme: nil, quit_errors: true)
      StockImportingLogEntity.destroy_all unless Rails.env.production?

      # Перенести в universe
      synced_at = Time.zone.now
      @vendor = vendor
      @worker = worker
      @scheme = scheme || build_scheme
      @quit_errors = quit_errors

      @vendor_logger = if quit_errors
                         VendorLogger.new vendor: vendor, synced_at: synced_at
                       else
                         FakeVendorLogger.instance
                       end
      @universe = Universe.new vendor: vendor, synced_at: synced_at, vendor_logger: @vendor_logger
    end

    def perform(options = {})
      raise NoLogin unless vendor.ms_valid?

      vendor_logger.create!

      do_import options

      # Net::ReadTimeout
    rescue Exception => e
      Bugsnag.notify e, metaData: { vendor_id: vendor.id }
      raise e if Rails.env.development?

      binding.debug_error
      vendor_logger.fatal_error "[#{e.class}] #{e}" if vendor_logger.present?

      handle_bell_errors e

      handle_error e unless SILENT_ERRORS.include? e.class

      raise e if !quit_errors || e.is_a?(Exception)
    ensure
      vendor_logger.try :finish!
    end

    private

    attr_reader :vendor, :vendor_logger, :mgu, :universe, :worker, :scheme, :quit_errors

    def add_bell(err)
      vendor.update_column :stock_auto_syncing, false
      vendor.bells_handler.add_error err, login: vendor.moysklad_login
    end

    def handle_error(err)
      context = { vendor_id: vendor.id, version: AppVersion.to_s }
      context[:log_entity_id] = vendor_logger.log_entity.try(:id)
      context[:record] = err.record if err.is_a? ActiveRecord::RecordInvalid
      Bugsnag.notify err, metaData: context
    end

    def handle_bell_errors(err)
      if err.is_a?(Moysklad::Client::ResourceForbidden) ||
          err.is_a?(Moysklad::Client::UnauthorizedError) ||
          err.is_a?(NoLogin)
        add_bell err
      end
    end

    def do_import(options = {})
      vendor_logger.debug "Фильтр #{options}"
      scheme.each do |klass|
        worker_store class: klass
        begin
          vendor_logger.debug "Импортирую ресурс #{klass}"
          klass
            .new(options.merge(universe: universe))
            .perform!
        rescue StandardError => e
          vendor_logger.error e
          # Например может быть просто запрещена выгрузка модификаций
          # {"errors":[{"error":"Ваш тарифный план не позволяет работать с модификациями","code":15004,"moreInfo":"https://online.moysklad.ru/api/remap/1.1/doc#обработка-ошибок-15004"}]}
          raise e unless e.is_a? Moysklad::Client::ResourceForbidden
        end
        vendor_logger.flush!
      end
    end

    def build_scheme
      # return [
      # MoyskladImporting::OrganizationsUpdater,
      # MoyskladImporting::ClientsUpdater,
      # MoyskladImporting::WarehouseUpdater,
      # MoyskladImporting::DictionaryUpdater,
      # MoyskladImporting::DictionaryEntitiesUpdater,
      # MoyskladImporting::PropertiesUpdater,
      # MoyskladImporting::GoodFoldersUpdater,
      # MoyskladImporting::GoodsUpdater,
      # MoyskladImporting::FeaturesUpdater,
      # MoyskladImporting::StockUpdater
      # ]
      scheme = if vendor.is_stock_do_sync_categories
                 MoyskladImporting::Scheme::FULL
               else
                 MoyskladImporting::Scheme::BASIC
               end

      if vendor.vendor_organizations.empty? || vendor.vendor_organization.blank?
        scheme = scheme.dup.unshift MoyskladImporting::OrganizationsUpdater
      end

      if vendor.is_stock_do_sync_clients?
        scheme += [MoyskladImporting::ClientsUpdater]
      end

      scheme
    end

    def worker_store(*args)
      return unless worker

      worker.send :store, *args
    end
  end
end
