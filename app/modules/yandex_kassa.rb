module YandexKassa
  extend AutoLogger

  API_URL = 'https://yoomoney.ru/eshop.xml'.freeze
  API_DEMO_URL = 'https://demomoney.yandex.ru/eshop.xml'.freeze

  REQUEST_DATETIME = :requestDatetime
  INVOICE_ID = :invoiceId
  SHOP_ID = :shopId

  ACTION = :action
  ORDER_SUM_AMOUNT = :orderSumAmount
  ORDER_SUM_CURRENCY_PAYCASH = :orderSumCurrencyPaycash
  ORDER_SUM_BANK_PAYCASH = :orderSumBankPaycash
  CUSTOMER_NUMBER = :customerNumber
  ORDER_NUMBER = :orderNumber

  PAYMENT_TYPE = :paymentType

  PAYMENT_METHODS = %i[
    AC PC MC GP WM SB MP AB MA PB QW KV QP
  ].freeze
  DEFAULT_PAYMENT_METHOD = ''.freeze

  class JsonMoney
    def initialize(money)
      @money = money
    end

    def to_json(_options = nil)
      '%.2f' % @money.to_f
    end
  end
end
