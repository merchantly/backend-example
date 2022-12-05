class MoyskladImporting::Orderer
  MAX_ORDER_POSITIONS = 100

  def initialize(order: nil)
    @order = order or raise 'No order'
  end

  def make_order
    if stock.ms_order_uuid.present?
      log_error "Заказ уже оформлен. UUID: #{stock.ms_order_uuid}"
      return
    else
      log_info 'Резервирование на складе'
    end

    order.with_lock do
      export_order MoyskladImporting::OrderFactory.new(order).build
    end

    update_stock!(:reserve)
  end

  def cancel_order
    order.with_lock do
        if stock.ms_order_uuid.present?
          log_info "Снятие резервирования на складе: UUID: #{stock.ms_order_uuid}"
          resource.delete stock.ms_order_uuid
          stock.update!(
            ms_order_uuid: nil,
            is_reserved: false,
            unreserved_at: Time.zone.now,
            unreservation_result: 1
          )
        else
          log_error 'Нет UUID для снятия с резерва'
        end
    rescue Moysklad::Client::NoResourceFound
        stock.update!(
          ms_order_uuid: nil,
          is_reserved: false,
          unreserved_at: Time.zone.now,
          unreservation_result: -1
        )
        log_error 'Ошибка снятия с резерва: На складе нет такого заказа'
    rescue StandardError => e
        stock.update!(
          unreserved_at: Time.zone.now,
          unreservation_result: -2
        )
        log_error "Ошибка снятия с резерва #{e}"
        binding.debug_error
        Rails.logger.error e
        Bugsnag.notify e, metaData: { vendor_id: order.vendor_id, vendor_host: order.vendor.home_url, order_id: order.id }
    end

    update_stock!(:unreserve)
  end

  private

  attr_reader :order

  def export_order(order_to_export)
    if Rails.env.development?
      Rails.logger.warn '!!! Игнорирую make_order в development'
      return
    end

    # if order positions better 100
    positions_count = order_to_export.positions.count
    extra_positions = if positions_count > MAX_ORDER_POSITIONS
                        order_to_export.positions.slice!(MAX_ORDER_POSITIONS, positions_count)
                      else
                        []
                      end

    ms_order = resource.create order_to_export

    log_info "Зарезервирован заказ. UUID: #{ms_order.id}", dump: ms_order.dump
    stock.update!(
      ms_order_uuid: ms_order.id,
      ms_order_dump: ms_order.dump,
      is_reserved: true,
      reserved_at: Time.zone.now,
      reservation_result: 1
    )

    export_order_positions ms_order, extra_positions if extra_positions.present?

    # <Moysklad::Client::MethodNotAllowedError: {"errors":[{"error":"Ошибка сохранения объекта: нарушено ограничение уникальности параметра 'name'","code":3006,"parameter":"name","moreInfo":"https://online.moysklad.ru/api/remap/1.1/doc#обработка-ошибок-3006"}]}>
    #
  rescue StandardError => e
    order.vendor.bells_handler.add_error e, order_id: order.id if e.is_a?(Moysklad::Client::NoResourceFound)

    stock.update!(
      reservation_result: -1
    )
    log_error "Ошибка резервирования #{e}"
    binding.debug_error
    Rails.logger.error e
    # Bugsnag.notify err, metaData: { vendor_id: order.vendor_id, order_id: order.id, order_to_export: order_to_export.as_json, ms_order_dump: ms_order.try(:dump) }
    raise e
  end

  def export_order_positions(ms_order, positions)
    positions.each do |position|
      resource.create_position ms_order.id, position
    end
  end

  def universe
    @universe ||= order.vendor.moysklad_universe
  end

  def log_error(message)
    message = "moysklad.ru: #{message}"
    order.log! message
    MoyskladImporting.logger.error message: message, order_id: order.id
  end

  def log_info(message, args = {})
    order.log! message
    args.reverse_merge! message: message, order_id: order.id
    MoyskladImporting.logger.info args
  end

  def stock
    order.order_remote_stock
  end

  def update_stock!(type)
    log_info 'Обновляем остатки'

    ProductStockUpdateWorker.perform_async order.id, type
  end

  def resource
    order.vendor.moysklad_universe.customer_orders
  end
end
