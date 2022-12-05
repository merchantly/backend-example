module Gsdk
  extend AutoLogger

  ONLINE_PAYMENT = 'ONLINE_PAYMENT'.freeze
  E_INVOICE = 'E_INVOICE'.freeze
  PAYMENT_TYPES = [ONLINE_PAYMENT, E_INVOICE].freeze
  GSDK_RESPONSE_SUCCESS = 'OK'.freeze
  GSDK_RESPONSE_ERROR = 'ERROR'.freeze

  def self.api_url
    "#{Rails.application.routes.url_helpers.api_url(protocol: 'https', port: 443, subdomain: Settings.api_subdomain)}v1/callbacks/gsdk/notify"
  end
end
