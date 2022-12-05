class BasePaymentService
  attr_reader :response

  SUCCESS_RESPONSE = 'complete'.freeze

  def initialize(vendor:, params:)
    @vendor = vendor
    @params = params
  end

  private

  attr_reader :vendor, :params

  delegate :order, to: :payment

  def error_catched(err)
    Rails.logger.error "#{vendor.id} #{payment}: #{err}"
    Bugsnag.notify err, metaData: { payment: payment, vendor_id: vendor.id }

    retry_response("Внутренняя ошибка #{err}")
  end

  def success_payment
    order.order_payment.pay! payment
    success_response
  end

  def success_response
    SUCCESS_RESPONSE
  end

  def failed_payment
    order.order_payment.fail! payment if order.present?
    retry_response('Платеж не валидный или не полный')
  end

  def retry_response(message)
    message
  end

  def payment; end

  Error = Class.new StandardError

  InvalidPayment = Class.new Error
  NoSignature    = Class.new Error
  OrderNotFound  = Class.new Error
end
