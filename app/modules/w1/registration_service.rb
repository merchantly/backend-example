# encoding: utf-8

#
# TODO: Выполнять перерегистрацию:
# 1. При смене домена.
# 2. При смене валюты.
class W1::RegistrationService
  require 'w1/registration_service/errors'

  API_URL = 'https://api.w1.ru/KiiioskApi/merchant'.freeze

  def initialize(vendor_walletone)
    vendor_walletone = vendor_walletone.vendor_walletone if vendor_walletone.is_a?(Vendor)
    @vendor_walletone = vendor_walletone
  end

  def register!(force = false)
    return if (!force && vendor_walletone.state_approved?) || Secrets.w1.nil?

    vendor_walletone.validate_complete!

    if ENV['REGISTER_MERCHANT'] == 'fail'
      raise W1::RegistrationService::ParamFormatError.new(500, { Description: 'Какая-то ошибка' }, 'body')
    end

    if Rails.env.production? || Rails.env.test? || ENV['REGISTER_MERCHANT']
      response = make_request

      if response.code.to_i == 200
        response_json = MultiJson.load response.body.to_s.force_encoding('utf-8')
      else
        fail_error! response
      end
    else

      # Во всех остальных случаях делаем фейковые данные
      response_json = {
        'MerchantId' => '9999999999999',
        'MerchantSignKey' => 'sign_key',
        'MerchantToken' => 'token',
        'OwnerUserId' => '000000000000000'
      }
    end

    vendor_walletone.update! merchant_id: response_json['MerchantId'],
                             merchant_sign_key: response_json['MerchantSignKey'],
                             merchant_token: response_json['MerchantToken'],
                             owner_user_id: response_json['OwnerUserId']

    vendor_walletone.approve!
    success_log

    vendor_walletone
  rescue StandardError => e
    W1.log "Ошибка #{e} регистрации мерчанта W1 [vendor_id=#{vendor_walletone.vendor_id}]"
    vendor_walletone.error_approving!
    Bugsnag.notify e, metaData: {
      response_body: response.try(:body),
      response_code: response.try(:code),
      vendor_id: vendor_walletone.vendor_id,
      vendor_walletone: vendor_walletone.as_json
    }
    SmsWorker.sms_to_support "Ошибка регистрации мерчанта #{vendor_walletone.vendor_id} - #{e}"

    raise e
  end

  private

  attr_reader :vendor_walletone

  def fail_error!(response)
    response_body = response.body.to_s.force_encoding('utf-8')
    response_json = MultiJson.load(response_body) rescue nil

    Rails.logger.error "W1 registration request: #{request_body}"
    Rails.logger.error "W1 registration response: #{response.code} #{response_body}"

    if response_json.is_a? Hash
      error_class = DETECTABLE_ERRORS.find { |e| e.detect? response_json['Error'] } || UnknownError
      raise error_class.new response.code, response_json, request_body
    else
      raise FailResponseError.new("[#{response.code}] #{response_body}")
    end
  end

  def success_log
    SmsWorker.sms_to_support "Новый мерчант #{vendor_walletone.vendor.home_url}, #{vendor_walletone.phone} #{vendor_walletone.full_name}"
    W1.log "Мерчант зарегистрирован W1 [vendor_id=#{vendor_walletone.vendor_id}] [merchant_id=#{vendor_walletone.merchant_id}]"
  end

  def make_request
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = request_body
    http.request request
  end

  def request_body
    @request_body ||= W1::RegistrationEntity.represent(vendor_walletone).to_json
  end

  def uri
    URI.parse API_URL
  end

  def kiosk_token
    Secrets.w1.kiosk_token
  end

  def headers
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{kiosk_token}"
    }
  end
end
