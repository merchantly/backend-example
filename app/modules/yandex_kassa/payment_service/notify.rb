require 'open-uri'

module YandexKassa
  class PaymentService::Notify
    attr_accessor :params, :vendor

    MD5_FIELDS = [
      ACTION, ORDER_SUM_AMOUNT, ORDER_SUM_CURRENCY_PAYCASH,
      ORDER_SUM_BANK_PAYCASH, SHOP_ID, INVOICE_ID, CUSTOMER_NUMBER
    ].freeze

    def initialize(params, vendor)
      @params = params
      @vendor = vendor
    end

    def accepted?
      sum_accepted? and secret_accepted?
    end

    def sum_accepted?
      order.total_with_delivery_price.to_s == params[ORDER_SUM_AMOUNT]
    end

    # yandex kassa передает md5 в верхнем регистре
    def secret_accepted?
      params[:md5].casecmp(md5.upcase).zero?
    end

    def md5
      Digest::MD5.hexdigest(md5_fields.join(';'))
    end

    def md5_fields
      MD5_FIELDS.map { |f| params[f] } + [vendor.yandex_kassa_secret]
    end

    def order_id
      params[ORDER_NUMBER]
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end
  end
end
