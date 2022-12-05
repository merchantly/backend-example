module MoyskladImporting
  class StockUpdater < Updater
    private

    def resource
      @resources ||= build_resource
    end

    def stockstores
      @stockstores ||= vendor
        .warehouses
        .alive
        .active
        .order(:id)
        .where.not(ms_stockstore_uri: nil)
        .pluck(:ms_stockstore_uri)
    end

    def build_resource
      # TODO Может использовать /report/stock/all ?
      if vendor.use_all_moysklad_warehouses?
        vendor.moysklad_universe.assortments.all
      else
        # проблемс: мойсклад возвращает остатки отдельно для каждого склада
        # поэтому обновлять последовательно ресурсы мы не можем - остатки останутся только от последнего склада

        # группируем остатки по consignmentUuid
        assortments = []

        stockstores.map do |stockstore|
          assortments += vendor.moysklad_universe.assortments.all(stockstore: stockstore)
        end

        stock_remains = assortments.group_by(&:id)

        # суммируем остатки со всех складов для каждого отдельного consignmentUuid
        stock_remains.map do |_id, remains|
          assortment = remains.first # всегда будет
          unless assortment.is_a? Moysklad::Entities::Service
            assortment.inTransit = remains.collect(&:inTransit).compact.sum
            assortment.quantity = remains.collect(&:quantity).compact.sum
            assortment.stock = remains.collect(&:stock).compact.sum
            assortment.reserve = remains.collect(&:reserve).compact.sum
          end
          assortment
        end
      end
    end

    def create_or_update(entity)
      model = super entity
      model.update_consignment_dump entity.dump.to_json
      model
    end

    def filtered?(entity)
      return false unless entity.is_a?(Moysklad::Entities::Product) || entity.is_a?(Moysklad::Entities::Variant)

      super(entity)
    end

    def find_model(assortment)
      case assortment
      when Moysklad::Entities::Variant
        vendor.product_items.by_externalcode(assortment.externalCode).take
      when Moysklad::Entities::Product, Moysklad::Entities::Bundle, Moysklad::Entities::Service
        vendor.products.by_externalcode(assortment.externalCode).take
      else
        binding.debug_error
        raise "Не обрабатываемый тип ассортимента #{assortment}"
      end
    end

    def build_model(assortment)
      raise MoyskladImporting::Errors::NoConsignmentForGood.new(assortment)
    end

    def archive_all_remains
      vendor.products.stock_linked.quantity_not_synced(synced_at).find_each(&:clean_stock!)
      vendor.product_items.stock_linked.quantity_not_synced(synced_at).find_each(&:clean_stock!)
    end

    def default_attributes(entity, _model)
      {
        ms_stockstores: stockstores.join(';'),
        quantity_synced_at: synced_at,
        # inTransit:        entity.inTransit,
        quantity: entity.quantity,
        stock: entity.stock,
        reserve: entity.reserve
      }
    end
  end
end
