module Robokassa
  class PaymentService::Notify
    include VendorsHelper

    MD5_FIELDS = [
      OUT_SUM, INV_ID
    ].freeze

    def initialize(params, vendor)
      @params = params
      @vendor = vendor
    end

    def accepted?
      secret_accepted?
    end

    def inspect
      params.to_hash
    end

    def secret_accepted?
      params[HASH].casecmp(md5.upcase).zero?
    end

    def md5
      Digest::MD5.hexdigest(md5_fields.join(':'))
    end

    def md5_fields
      MD5_FIELDS.map { |f| params[f] } + [order.payment_type.robokassa_second_password, "Shp_orderid=#{order_id}"]
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    private

    attr_accessor :params, :vendor

    def order_id
      params[ORDER_ID]
    end
  end
end
