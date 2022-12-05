module W1
  OPEN_API_URL = 'https://api.w1.ru/OpenApi/'.freeze

  NEW_CHECKOUT_URL = 'https://wl.walletone.com/checkout/checkout/Index'.freeze
  OLD_CHECKOUT_URL = 'https://www.walletone.com/checkout/default.aspx'.freeze

  API_CHECKOUT_URL = OLD_CHECKOUT_URL
  WEB_CHECKOUT_URL = NEW_CHECKOUT_URL

  WMI_SIGNATURE   = 'WMI_SIGNATURE'.freeze
  WMI_PAYMENT_NO  = 'WMI_PAYMENT_NO'.freeze
  WMI_ORDER_STATE = 'WMI_ORDER_STATE'.freeze

  extend LoggerConcern
  self.log_tag = :W1

  def self.generate_signature_from_options(options, md5_secret_key)
    generate_signature_from_list options.to_a, md5_secret_key
  end

  def self.generate_signature_from_list(list, md5_secret_key)
    values = list
             .reject { |e| e.first == WMI_SIGNATURE }
             .sort_by(&:first)
             .map(&:last)
    signature_string = [values, md5_secret_key].flatten.join
    Rails.logger.debug { "Walletone sign string '#{signature_string}'" }
    encoded_signature_string = signature_string.encode 'cp1251'
    Digest::MD5.base64digest(encoded_signature_string)
  rescue StandardError => e
    Bugsnag.notify e, metaData: { list: list }
    raise e
  end
end
