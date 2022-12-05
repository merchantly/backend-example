class Aqsi::Requestor
  include Virtus.model
  include AutoLogger

  AqsiClientKeyEmptyError = Class.new StandardError
  AqsiShopIdEmptyError = Class.new StandardError
  AqsiClientGroupUuidEmptyError = Class.new StandardError

  CONTENT_TYPE = 1 # 1 - Приход, 2 - Возврат прихода, 3 - Расход, 4 - Возврат расхода

  TAX_IDS = {
    tax_ru_1: 6,
    tax_ru_2: 5,
    tax_ru_3: 2,
    tax_ru_4: 1,
    tax_ru_5: 4,
    tax_ru_6: 3,
    tax_ru_7: 1,
    tax_ru_8: 3
  }.freeze

  attribute :order, Order

  def perform
    logger.info "Start: order_id: #{order.id}"

    response = client.create_order data

    logger.info "Success: order_id: #{order.id}, result: #{response}"
  rescue StandardError => e
    logger.error "Error: order_id: #{order.id}, error: #{e.message}"
    raise e
  end

  private

  delegate :payment_type, :vendor, :order_prices, to: :order

  def client
    @client ||= Aqsi::Client.new(client_key: client_key, test_mode: test_mode)
  end

  def test_mode
    payment_type.is_online_kassa_test_mode?
  end

  def client_key
    payment_type.online_kassa_aqsi_client_key.presence || raise(Aqsi::AqsiClientKeyEmptyError)
  end

  def shop_id
     payment_type.online_kassa_aqsi_shop_id.presence || raise(Aqsi::AqsiShopIdEmptyError)
  end

  def data
    {
      shop: shop_id,
      clientId: client_aqsi_id,
      number: order.public_id,
      id: order.id.to_s,
      content: content,
      dateTime: order.created_at,
      deliveryAddress: order.address,
    }
  end

  def content
    {
      type: CONTENT_TYPE,
      positions: lines.compact,
      customerContact: (order.phone.presence || order.email)
    }
  end

  def lines
    order_prices.items.map do |item|
      {
        quantity: item.quantity.to_f,
        price: item.price.to_f,
        tax: tax_id(item.tax_type),
        paymentMethodType: order.payment_type.online_kassa_payment_method,
        paymentSubjectType: order.payment_type.online_kassa_payment_object,
        text: item.title
      }
    end + [delivery_line, package_line]
  end

  def delivery_line
    return if order.delivery_price.zero?

    {
      quantity: 1.0,
      price: order_prices.delivery.price.to_f,
      tax: tax_id(order_prices.delivery.tax_type),
      paymentMethodType: order.payment_type.online_kassa_payment_method,
      paymentSubjectType: order.payment_type.online_kassa_payment_object,
      text: order.delivery_type.title
    }
  end

  def package_line
    return if order.package_price.zero?

    {
      quantity: 1.0,
      price: order_prices.package.price.to_f,
      tax: tax_id(order_prices.package.tax_type),
      paymentMethodType: order.payment_type.online_kassa_payment_method,
      paymentSubjectType: order.payment_type.online_kassa_payment_object,
      text: order_prices.package.title
    }
  end

  def tax_id(tax_type)
    raise TaxEmptyError if tax_type.blank?

    TAX_IDS[tax_type.to_sym] || raise("Tax type unknown: #{tax_type}")
  end

  def client_aqsi_id
    if order.client.aqsi_uuid.blank?
      response = client.create_client(client_data)

      order.client.update_column :aqsi_uuid, response['id']

      response['id']
    else
      order.client.aqsi_uuid
    end
  end

  def client_data
    {
      fio: order.client.name,
      mainPhone: order.client.phone.to_s,
      email: order.client.email.to_s,
      group: {
        id: client_group_id
      }
    }
  end

  def client_group_id
    payment_type.online_kassa_aqsi_client_group_uuid || raise(Aqsi::AqsiClientGroupUuidEmptyError)
  end
end
