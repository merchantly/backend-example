module RbkMoney
  class PaymentService::Notify
    include VendorsHelper

    HASH = 'Content-Signature'.freeze

    def initialize(params, headers, data, vendor)
      @params = params.deep_symbolize_keys
      @vendor = vendor
      @headers = headers
      @data = data
    end

    def accepted?
      # FIXME secret не совпадают
      paid? # && secret_accepted?
    end

    def inspect
      {
        headers: headers,
        data: data,
        params: params.to_hash
      }
    end

    def secret_accepted?
      public_key = OpenSSL::PKey::RSA.new vendor.rbk_money_public_key

      public_key.verify(OpenSSL::Digest.new('SHA256'), signature, data)
    end

    def order
      @order ||= vendor.orders.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    private

    attr_accessor :params, :vendor, :headers, :data

    def order_id
      params[:invoice][:metadata][:order_id]
    end

    def paid?
      %w[PaymentProcessed PaymentCaptured].include? params[:eventType].to_s
    end

    def signature
      Base64.decode64 headers[HASH].gsub(/alg=(\S+);\sdigest=/, '')
    end
  end
end
