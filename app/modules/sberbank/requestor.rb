module Sberbank
  class Requestor
    include Virtus.model
    include RoutesConcern

    ResponseError = Class.new StandardError
    ApiTokenEmptyError = Class.new StandardError

    MAX_DESCRIPTION_LENGTH = 24

    attribute :order, Order

    URL = 'https://securepayments.sberbank.ru/payment/rest/register.do'.freeze
    TEST_URL = 'https://3dsec.sberbank.ru/payment/rest/register.do'.freeze

    def perform
      return if order_payment.sberbank_form_url.present?

      result = Faraday.post(url, params)

      json_result = JSON.parse result.body

      raise ResponseError.new json_result.to_s if json_result['formUrl'].blank?

      order_payment.update sberbank_form_url: json_result['formUrl']

      order_payment.sberbank_form_url
    rescue StandardError => e
      Sberbank.logger.error "Произошла ошибка: order_id: #{order.id}, message: #{e}"

      if e.is_a?(ResponseError) || e.is_a?(ApiTokenEmptyError)
        order.vendor.bells_handler.add_error e, error: e.to_s
      else
        Bugsnag.notify e
      end

      nil
    end

    private

    def params
      {
        token: token,
        orderNumber: order.id,
        amount: order.total_with_delivery_price.exchange_to('RUB').cents,
        returnUrl: success_vendor_payments_sberbank_url(host: order.vendor.home_url),
        failUrl: failure_vendor_payments_sberbank_url(host: order.vendor.home_url),
        description: description
      }
    end

    def token
      order.payment_type.sberbank_api_token || raise(ApiTokenEmptyError.new)
    end

    def description
      order.description.gsub(/[[:cntrl:]]/, '').truncate(MAX_DESCRIPTION_LENGTH)
    end

    def order_payment
      order.order_payment
    end

    def url
      order.payment_type.sberbank_is_test? ? TEST_URL : URL
    end
  end
end
