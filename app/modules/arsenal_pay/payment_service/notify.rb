module ArsenalPay
  class PaymentService::Notify
    include VendorsHelper

    STATUS = 'STATUS'.freeze
    STATUS_CHECK = 'check'.freeze
    STATUS_PAYMENT = 'payment'.freeze
    STATUS_REVERSAL = 'reversal'.freeze
    STATUS_REFUNDED = 'refunded'.freeze

    HASH = 'SIGN'.freeze
    ID = 'ID'.freeze
    FUNCTION = 'FUNCTION'.freeze
    RRN = 'RRN'.freeze
    PAYER = 'PAYER'.freeze
    AMOUNT = 'AMOUNT'.freeze
    ACCOUNT = 'ACCOUNT'.freeze
    OFD = 'OFD'.freeze
    FORMAT = 'FORMAT'.freeze

    def initialize(params)
      @params = params
    end

    def accepted?
      payment? && secret_accepted?
    end

    def refunded?
      status_refunded?
    end

    def reversal?
      status_reversal?
    end

    def check?
      status_check?
    end

    def payment?
      status_payment?
    end

    def ofd?
      (params[OFD].to_s == '1') && (format == 'json')
    end

    def format
      params[FORMAT]
    end

    def order
      @order ||= Order.find_by_id(order_id) || raise("Не найден заказ #{order_id}")
    end

    delegate :vendor, to: :order

    def inspect
      params.to_hash
    end

    private

    def status_check?
      params[STATUS] == STATUS_CHECK
    end

    def status_payment?
      params[STATUS] == STATUS_PAYMENT
    end

    def status_reversal?
      params[STATUS] == STATUS_REVERSAL
    end

    def status_refunded?
      params[STATUS] == STATUS_REFUNDED
    end

    attr_accessor :params

    def secret_accepted?
      params[HASH].casecmp(md5.upcase).zero?
    end

    # md5(md5(id).md5(function).md5(rrn).md5(payer).md5(amount).md5(account).md5(status).md5(password))
    def md5
      Digest::MD5.hexdigest(
        [
          params[ID],
          params[FUNCTION],
          params[RRN],
          params[PAYER],
          params[AMOUNT],
          params[ACCOUNT],
          params[STATUS],
          order.payment_type.arsenal_pay_password
        ].map { |param| Digest::MD5.hexdigest(param) }.join
      )
    end

    def order_id
      params[ACCOUNT]
    end
  end
end
