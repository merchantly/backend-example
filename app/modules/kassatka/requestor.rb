module Kassatka
  class Requestor
    include Virtus.model

    KassatkaDataEmptyError = Class.new StandardError
    ResponseError = Class.new StandardError
    TaxEmptyError = Class.new StandardError

    MULTIPLICATOR = 1000

    TAX_IDS = {
      tax_ru_1: 4,
      tax_ru_2: 3,
      tax_ru_3: 2,
      tax_ru_4: 1,
      tax_ru_5: 6,
      tax_ru_6: 5
    }.freeze

    attribute :order, Order

    def perform
      Kassatka.logger.info "Start: order_id: #{order.id}"

      result = connection.post do |req|
        req.headers['Content-type'] = 'application/json'
        req.body = data.to_json
      end

      response = JSON.parse result.body

      raise ResponseError.new unless response['Response']['Error'].zero?

      Kassatka.logger.info "Success: order_id: #{order.id}, result: #{response}"

      response
    rescue StandardError => e
      Kassatka.logger.error "Error: order_id: #{order.id}, error: #{e}"
      raise e
    end

    private

    delegate :payment_type, :vendor, :order_prices, to: :order

    def url
      "http://#{online_kassa_kassatka_address}:#{online_kassa_kassatka_port}/fr/api/v2/Complex"
    end

    def connection
      @connection ||= Faraday::Connection.new url # , ssl: { client_cert: online_kassa_kassatka_cert, client_key: online_kassa_kassatka_key }
    end

    def data
      {
        Device: 'auto',
        RequestId: "#{order.id}-#{Time.now.to_i}",
        Lines: lines.compact,
        NonCash: [order_prices.total_price.cents, 0, 0],
        TaxMode: tax_mode,
        PhoneOrEmail: (order.phone.presence || order.email),
      }
    end

    def lines
      order_prices.items.map do |item|
        {
          Qty: item.quantity * MULTIPLICATOR,
          Price: item.price.cents,
          PayAttribute: 4,
          TaxId: tax_id(item.tax_type),
          Description: item.title
        }
      end + [delivery_line, package_line]
    end

    def delivery_line
      return if order.delivery_price.zero?

      {
        Qty: 1 * MULTIPLICATOR,
        Price: order_prices.delivery.price.cents,
        PayAttribute: 4,
        TaxId: tax_id(order_prices.delivery.tax_type),
        Description: order_prices.delivery.title
      }
    end

    def package_line
      return if order.package_price.zero?

      {
        Qty: 1 * MULTIPLICATOR,
        Price: order_prices.package.price.cents,
        PayAttribute: 4,
        TaxId: tax_id(order_prices.package.tax_type),
        Description: order_prices.package.title
      }
    end

    def online_kassa_kassatka_address
      payment_type.online_kassa_kassatka_address || raise(KassatkaDataEmptyError)
    end

    def online_kassa_kassatka_port
      payment_type.online_kassa_kassatka_port || raise(KassatkaDataEmptyError)
    end

    def tax_mode
      vendor.tax_mode || raise(TaxEmptyError)
    end

    def tax_id(tax_type)
      raise TaxEmptyError if tax_type.blank?

      TAX_IDS[tax_type.to_sym] || raise("Tax type unknown: #{tax_type}")
    end
  end
end
