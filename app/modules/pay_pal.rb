module PayPal
  API_URL = 'https://www.paypal.com/cgi-bin/websrc'.freeze
  API_SANBOX_URL = 'https://www.sandbox.paypal.com/cgi-bin/websrc'.freeze

  PAYPAL_CUSTOM = 'custom'.freeze
  PAYPAL_ORDER_ID = 'order_id'.freeze
  PAYPAL_ORDER_AMOUNT = 'order_amount'.freeze
  PAYPAL_PAYMENT_STATUS = 'payment_status'.freeze

  InvalidByteError = Class.new StandardError
end
