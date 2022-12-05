class MoyskladImporting::OrderFactory
  TAGS = ['merchantly'].freeze
  Error = Class.new StandardError
  NoItemsInOrder = Class.new Error

  def initialize(order)
    raise 'Must be an Order' unless order.is_a? Order

    @order = order
    # raise Error, 'МойСклад не настроен' unless vendor.ms_valid?
  end

  # http://wiki.moysklad.ru/wiki/Пример_загрузки_заказа_покупателя_через_REST_API
  # https://online.moysklad.ru/exchange/rest/ms/xml/Metadata/list?filter=code%3DCustomerOrder
  def build
    raise Error, 'НДС не поддерживается' if vendor.vat.present?

    ms_order = Moysklad::Entities::CustomerOrder.new
    ms_order.vatIncluded  = vendor.vat.present?
    ms_order.vatEnabled   = vendor.vat.present?
    ms_order.vatSum       = 0
    # ms_order.rate валюта
    ms_order.applicable   = true
    ms_order.store        = store_meta
    ms_order.name         = order_name
    ms_order.code         = order.id
    ms_order.moment       = Moysklad::Entities::Time.at(order.created_at.to_i, in: Time.zone)
    ms_order.positions    = order_positions
    ms_order.organization = organization_meta
    ms_order.agent        = agent_meta
    ms_order.description  = order_description
    ms_order.group        = group_meta if group_meta.present?
    # ms_order.sum = Moysklad::Entities::Price.from_money order.total_price

    ms_order
  rescue MoyskladImporting::OrderFactory::NoItemsInOrder => e
    Rails.logger.warn e
    order.log! 'У заказа нет позиций привязанных к складу. Нечего резервировать'
    raise e
  rescue StandardError => e
    order.log! "Ошибка: #{e}"
    raise e
  end

  private

  attr_reader :order

  delegate :vendor, to: :order

  def organization_meta
    raise Error, "У магазина #{vendor.home_url} [#{vendor.id}] не установлена организация для экспорта заказ" if vendor.vendor_organization.blank?

    vendor.vendor_organization.dumped_ms_entity
  rescue MoyskladEntity::NoMsDump
    raise Error, "У магазина #{vendor.home_url} [#{vendor.id}] отсутствует информация об организации для экспорта (обновите информацию в интеграции с МойСклад)"
  end

  def agent_meta
    find_or_create_counterparty order.client
  end

  def group_meta
    @group_meta ||= build_group_meta
  end

  def build_group_meta
    return if vendor.vendor_group.blank?

    vendor.vendor_group.dumped_ms_entity
  end

  def order_name
    name = "kiosk-#{order.title}"

    name = "TEST-#{name}" unless Rails.env.production?
    name
  end

  def store_meta
    return if vendor.order_warehouse.blank?

    vendor.order_warehouse.dumped_ms_entity
  end

  def order_positions
    positions = order.order_prices.items.map do |i|
      order_position_entity i
    end

    positions << order_position_entity(order.order_prices.package) unless order.package_price.zero?

    positions.compact.presence || raise(NoItemsInOrder)
  end

  def order_position_entity(i)
    Moysklad::Entities::CustomerOrderPosition.new(
      quantity: i.quantity,
      reserve: i.quantity,
      price: i.price.cents,
      discount: 0, # расчитывается как в онлайн-кассах - через order_prices
      vat: i.vat.to_i,
      assortment: i.good.dumped_ms_entity
    )
  rescue MoyskladEntity::NoMsDump => e
    Rails.logger.warn e
    # Bugsnag.notify err, metaData: { order_item_id: i.id, good: i.good }, severity: :debug
    order.log! "У позиции (#{i.good.title} / #{i.good.ident}) отсутсвует привязка в Moysklad. Не возможно ее зарезервировать"
    nil
  end

  def order_description
    comment = order.comment.present? ? "Комментарий клиента: #{order.comment}" : nil
    [
      comment.presence,
      '---------',
      "Ссылка на сайт: #{order.operator_url}",
      "Оплата: #{order.payment_type}",
      "Доставка: #{order.delivery_type}",
      "Покупатель: #{order.name} #{order.phone} #{order.email}",
      "#{order.city_title} #{order.address}",
      "Стоимость заказа без доставки: #{order.total_price.format}",
      "Стоимость доставки: #{order.delivery_price.try(:format) || 'не указана'}",
      "Полная стоимость с доставкой: #{order.total_with_delivery_price.format}",
      "Скидка: #{order.discount_price.format} (#{order.discount}%)"
    ].compact.join("\n")
  end

  def update_client(client, counterparty)
    client.update!(
      ms_uuid: counterparty.id,
      externalcode: counterparty.externalCode,
      stock_synced_at: Time.zone.now
    )
    client.update_stock_dump counterparty.dump.to_json
  rescue StandardError => e
    Bugsnag.notify e, metaData: { client_id: client.id, counterparty: counterparty }
  end

  def find_or_create_counterparty(client)
    return client.dumped_ms_entity if client.stock_dump.present? && find_counterparty_by_uuid(client)

    counterparty = find_counterparty_by_uuid(client) || find_counterparty_by(:phone, client) || find_counterparty_by(:email, client) || create_counterparty(client)

    update_client client, counterparty if (client.ms_uuid != counterparty.id) && (client.externalcode != counterparty.externalCode)
    counterparty
  end

  def find_counterparty_by_uuid(client)
    return nil if client.ms_uuid.blank?

    universe.counterparties.get(client.ms_uuid)
  rescue Moysklad::Client::NoResourceFound
    nil
  end

  def find_counterparty_by(key, client)
    value = client.send key
    return nil if value.blank?

    universe.counterparties.list(filter: "#{key}=#{value}").rows.first
  end

  def create_counterparty(client)
    cp = build_counterparty(client)
    universe.counterparties.create cp
  end

  def build_counterparty(client)
    Moysklad::Entities::Counterparty.new(
      name: client.name,
      externalCode: client.externalcode,
      actualAddress: client.address,
      email: client.email.to_s,
      phone: client.phone.to_s,
      tags: TAGS,
      inn: client.inn,
      kpp: client.kpp,
      ogrn: client.ogrn,
      okpo: client.okpo,
      description: client.description,
      legalTitle: client.legal_title
    )
  end

  def universe
    vendor.moysklad_universe
  end
end
