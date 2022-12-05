module VendorPaymentKeys
  extend ActiveSupport::Concern

  CASH_KEY = 'CASH'.freeze
  TERMIAL_PAYMENT_KEY = 'TERMINAL_PAYMENT'.freeze
  ONLINE_PAYMENT_KEY = 'ONLINE_PAYMENT'.freeze
  E_INVOICE_KEY = 'E_INVOICE'.freeze
  PAYMENT_WITH_COIN = 'PAYMENT_WITH_COIN'.freeze

  KEYS = [CASH_KEY, TERMIAL_PAYMENT_KEY, ONLINE_PAYMENT_KEY, E_INVOICE_KEY, PAYMENT_WITH_COIN].freeze
  DEFAULT_KEY = ONLINE_PAYMENT_KEY

  KEY_AGENT = {
    CASH: 'OrderPaymentDirect',
    TERMINAL_PAYMENT: 'OrderPaymentDirect',
    ONLINE_PAYMENT: 'OrderPaymentGeideaPayment',
    E_INVOICE: 'OrderPaymentGeideaPayment',
    PAYMENT_WITH_COIN: 'OrderPaymentGeideaPayment'
  }.freeze

  included do
    enumerize :payment_key, in: KEYS, default: DEFAULT_KEY
  end

  def cash_key?
    payment_key == CASH_KEY
  end
end
