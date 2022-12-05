module Sberbank
  class PaymentService::Notify
    include VendorsHelper

    HASH = 'checksum'.freeze
    ORDER_ID = 'orderNumber'.freeze
    STATUS = 'status'.freeze
    STATUS_SUCCESS = '1'.freeze
    OPERATION = 'operation'.freeze
    OPERATION_DEPOSITED = 'deposited'.freeze
    OPERATION_REFUNDED = 'refunded'.freeze

    def initialize(params, vendor)
      @params = params
      @vendor = vendor
    end

    def refunded?
      operation_refunded?
    end

    def accepted?
      operation_deposited? && status_success? && secret_accepted?
    end

    def authorized?
      status_authorized?
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    def inspect
      params.to_hash
    end

    private

    def operation_refunded?
      params[OPERATION] == OPERATION_REFUNDED
    end

    def operation_deposited?
      params[OPERATION] == OPERATION_DEPOSITED
    end

    def status_success?
      params[STATUS].to_s == STATUS_SUCCESS
    end

    attr_accessor :params, :vendor

    def secret_accepted?
      params[HASH].casecmp(hmac_sha256.upcase).zero?
    end

    def hmac_sha256
      hash = params.to_h
      hash = hash.stringify_keys
      hash = hash.except(HASH)

      array = hash.sort

      str = "#{array.flatten.join(';')};"

      OpenSSL::HMAC.hexdigest('SHA256', order.payment_type.sberbank_private_key, str)
    end

    def order_id
      params[ORDER_ID]
    end
  end
end
