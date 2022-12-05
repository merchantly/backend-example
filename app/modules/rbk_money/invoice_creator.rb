class RbkMoney::InvoiceCreator
  include Virtus.model
  include AutoLogger

  attribute :order, Order, require: true

  def perform
    raise RbkMoneyNotConfigured if api_key.blank? || shop_id.blank?

    conn = Faraday.new url: RbkMoney::CREATE_INVOICE_URL

    response = conn.post do |req|
      req.headers['X-Request-ID'] = SecureRandom.uuid[0..7]
      req.headers['Authorization'] = "Bearer #{api_key}"
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.headers['Accept'] = 'application/json'

      req.body = json_data.to_json
    end

    result = JSON.parse response.body

    logger.info "order_id: #{order.id} result: #{result}"

    raise RbkMoneyResultError, [result['code'], result['message']].join(': ') if response.status == 400
    raise RbkMoneyResultError, [result['name'], result['errorType']].join(': ') if result['errorType'].present?

    RbkMoney::Invoice.new(
      id: result['invoice']['id'],
      access_token: result['invoiceAccessToken']['payload'],
      order: order,
      description: result['invoice']['description'],
      title: result['invoice']['product']
    )
  end

  private

  def json_data
    {
      shopID: shop_id,
      dueDate: order.created_at.strftime('%Y-%m-%dT%H:%M:%S.%MZ'), # "2017-09-27T15:21:51.002Z",
      amount: order.total_with_delivery_price.cents,
      currency: order.currency.to_s,
      product: "Заказ номер #{order.id}",
      description: order.description,
      cart: cart_json,
      metadata: {
        order_id: order.id
      }
    }
  end

  def cart_json
    items = order.items.map do |order_item|
      {
        price: order_item.price.cents,
        product: order_item.title,
        quantity: order_item.quantity
        # "taxMode":{
        #   "rate":"18%",
        #   "type":"InvoiceLineTaxVAT"
        # }
      }
    end

    if order.delivery_price.to_f.positive?
      items << {
        price: order.delivery_price.cents,
        product: 'delivery',
        quantity: 1
      }
    end

    items
  end

  def api_key
    @api_key ||= order.vendor.rbk_money_secret
  end

  def shop_id
    @shop_id ||= order.vendor.rbk_money_eshop_id
  end

  RbkMoneyResultError = Class.new StandardError

  class RbkMoneyNotConfigured < StandardError
    def message
      I18n.t('errors.invoice_creator.rbk_money_not_configured')
    end
  end
end
