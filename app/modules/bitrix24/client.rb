class Bitrix24::Client
  include Bitrix24::Deal
  include Bitrix24::ProductRow
  include Bitrix24::Product
  include Bitrix24::Company
  include Bitrix24::Manager

  AuthorizationCodeError = Class.new StandardError

  def initialize(vendor:)
    @vendor = vendor

    raise 'Bitrix24 не сконфигурирован' if vendor_bitrix24.blank?

    check_expired_access_token
  end

  private

  attr_reader :vendor

  delegate :vendor_bitrix24, to: :vendor

  def check_expired_access_token
    create_access_token if access_token.blank?

    refresh_access_token if access_token.expires_at < Time.zone.now
  end

  def refresh_access_token
    new_access_token = client_without_access_token.refresh_token(access_token.refresh_token)

    return create_access_token if new_access_token.nil? || !new_access_token

    @access_token = create_bitrix_access_token(new_access_token)

    @client = Bitrix24CloudApi::Client.new(access_token: access_token.access_token, endpoint: vendor_bitrix24.url)
  end

  def create_bitrix_access_token(access_token)
    access_token = access_token.symbolize_keys

    Bitrix24::AccessToken.create!(
      access_token: access_token[:access_token],
      refresh_token: access_token[:refresh_token],
      expires_at: Time.zone.at(access_token[:expires_at] || access_token[:expires]),
      data: access_token,
      vendor_bitrix24: vendor_bitrix24
    )
  end

  def client
    @client ||= Bitrix24CloudApi::Client.new(access_token: access_token.access_token, endpoint: vendor_bitrix24.url)
  end

  def client_without_access_token
    return @client_without_access_token if @client_without_access_token.present?

    params = {
      endpoint: vendor_bitrix24.url,
      client_id: vendor_bitrix24.client_id,
      client_secret: vendor_bitrix24.client_secret,
      scope: 'crm',
      extension: 'json',
      redirect_uri: vendor.public_url
    }

    @client_without_access_token = Bitrix24CloudApi::Client.new(params)
  end

  def access_token
    @access_token ||= vendor_bitrix24.access_tokens.last
  end

  def create_access_token
    authorizaton_code_error if vendor_bitrix24.code.blank?

    access_token = client_without_access_token.get_access_token(vendor_bitrix24.code)

    authorizaton_code_error if access_token.nil?

    @access_token = create_bitrix_access_token(access_token)
  end

  def authorizaton_code_error
    authorize_url = client_without_access_token.authorize_url

    raise AuthorizationCodeError.new "Ошибка кода авторизации: Обновите код по ссылке #{authorize_url}"
  end
end
