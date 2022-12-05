module MoyskladImporting
  class Updater
    include Virtus.model
    include EntitiesFilter

    attribute :universe, MoyskladImporting::Universe
    attribute :uuids, Array
    attribute :filter, Hash

    def name
      self.class.name.sub('MoyskladImporting::', '').sub('Updater', '').underscore.pluralize
    end

    def perform!
      vendor_logger.update_data! "total_#{name}" => resource.count
      raise MaxResourcesCountError if resource.count > MAX_RESOURCES_COUNT

      resource.each_with_index do |entity, index|
        safe_create_or_update entity, index + 1 if filtered? entity
      end

      finish
      archive_all_remains if filter.empty?
    rescue Moysklad::Client::UnauthorizedError => e
      Bugsnag.notify e, metaData: { vendor_id: vendor.id }
      raise e
    end

    def preload
      # TODO Загружать только используемые в фильтре
      resource
    end

    private

    delegate :synced_at, :vendor, :vendor_logger, to: :universe

    def finish
      # implement upper
    end

    def total
      @total ||= resource.count
    end

    def safe_create_or_update(entity, index)
      vendor_logger.debug message: "Импортирую [#{index}/#{total}] #{entity.class} #{entity.try(:id)} #{entity.try(:name)}",
                          entity: entity.as_json
      create_or_update entity
      vendor_logger.update_data! "processed_#{name}" => index
    # rescue MoyskladImporting::Errors::NoRelationFound => err
    rescue StandardError => e
      binding.debug_error
      vendor_logger.error e
    end

    def resource
      raise 'not implemented'
    end

    def scope(_entity = nil)
      raise 'not implemented'
    end

    def archive_scope
      scope.alive
    end

    def find_scope(entity)
      scope entity
    end

    def build_scope(entity)
      scope entity
    end

    def archive_all_remains
      remains_scope.each(&:archive!)
    end

    def remains_scope
      archive_scope.stock_linked.not_synced(synced_at)
    end

    def find_model(entity)
      find_scope(entity).by_ms_entity(entity).take
    end

    def build_model(entity)
      build_scope(entity).build
    end

    # @param entity[Moysklad::Entities::Base]
    def create_or_update(entity)
      model = find_model(entity)
      if model.present?
        vendor_logger.update_data! "found_#{name}" => '+1'
      else
        model = build_model(entity)
        vendor_logger.update_data! "created_#{name}" => '+1'
      end

      model.assign_attributes default_attributes(entity, model)
      RepeatDeadLock.perform do
        update_from_moysklad model, entity
      end

      model
    end

    def real_changes(model)
      # Иногда бывает, например data={} и была data={}
      model.changes.reject { |_k, v| v[0] == v[1] }
    end

    def update_from_moysklad(model, entity)
      model.restore if model.archived?
      if model.changed?
        if real_changes(model).keys == ['stock_synced_at']
          model.update_column :stock_synced_at, model.stock_synced_at
        else
          binding.debug_error if real_changes(model).keys.include? 'quantity_stock_synced_at'
          model.save!
        end
      end
      model.update_stock_dump entity.dump.to_json
      model
    rescue StandardError => e
      binding.debug_error
      handle_error entity, e
    end

    def handle_error(entity, e)
      if e.record.errors.one? && e.record.errors.include?(:externalcode)
        exist_record = scope.find_by(externalcode: e.record.externalcode)

        message = "Из склада пришла запись #{entity.meta.href} с '#{entity.name}'"
        message << "Но в базе уже присутствует запись #{scope.model}##{exist_record.id} с externalcode=#{e.record.externalcode}, title='#{exist_record.title}', uuid=#{exist_record.ms_uuid}, archived=#{exist_record.archived?}"
      else
        message = e
        Bugsnag.notify e, metaData: { message: message.to_s, entity: entity.dump, vendor_id: vendor.id }
      end
      vendor_logger.error message: message.to_s, entity: entity.dump
    end

    def default_attributes(entity, _model = nil)
      {
        stock_synced_at: synced_at,
        externalcode: entity.try(:externalCode),
        ms_uuid: entity.id
      }
    end
  end
end
