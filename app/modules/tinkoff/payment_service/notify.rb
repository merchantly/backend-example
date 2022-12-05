module Tinkoff
  class PaymentService::Notify
    include VendorsHelper

    HASH = 'Token'.freeze
    ORDER_ID = 'OrderId'.freeze
    PASSWORD = 'Password'.freeze
    STATUS = 'Status'.freeze
    STATUS_CONFIRMED = 'CONFIRMED'.freeze
    STATUS_AUTHORIZED = 'AUTHORIZED'.freeze
    STATUS_PARTIAL_REFUNDED = 'PARTIAL_REFUNDED'.freeze
    STATUS_REFUNDED = 'REFUNDED'.freeze
    STATUS_REJECTED = 'REJECTED'.freeze
    STATUS_CANCELED = 'CANCELED'.freeze

    def initialize(params, vendor)
      @params = params
      @vendor = vendor
    end

    def canceled?
      status_canceled?
    end

    def accepted?
      status_accepted? && secret_accepted?
    end

    def refunded?
      status_refunded?
    end

    def rejected?
      status_rejected?
    end

    def authorized?
      status_authorized?
    end

    def partial_refunded?
      status_partial_refunded?
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    def inspect
      params.to_hash
    end

    private

    def status_canceled?
      params[STATUS] == STATUS_CANCELED
    end

    def status_rejected?
      params[STATUS] == STATUS_REJECTED
    end

    def status_accepted?
      params[STATUS] == STATUS_CONFIRMED
    end

    def status_refunded?
      params[STATUS] == STATUS_REFUNDED
    end

    def status_authorized?
      params[STATUS] == STATUS_AUTHORIZED
    end

    def status_partial_refunded?
      params[STATUS] == STATUS_PARTIAL_REFUNDED
    end

    attr_accessor :params, :vendor

    def secret_accepted?
      params[HASH].casecmp(sha256.upcase).zero?
    end

    def sha256
      hash = params.to_h
      hash = hash.stringify_keys
      hash = hash.except(HASH)

      hash[PASSWORD] = order.payment_type.tinkoff_password

      array = hash.sort

      str = array.reduce('') { |a, e| a + e[1].to_s }

      Digest::SHA256.hexdigest str
    end

    def order_id
      params[ORDER_ID]
    end
  end
end
