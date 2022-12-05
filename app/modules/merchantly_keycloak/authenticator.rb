class MerchantlyKeycloak::Authenticator
  include Rails.application.routes.url_helpers

  def initialize(*args)
    raise 'Keycloak disable' unless IntegrationModules.enable?(:keycloak)
    raise 'Installation file not exists' unless File.exist?(MerchantlyKeycloak::INSTALLATION_FILE_PATH)

    super(*args)
  end

  def url_login_redirect
    client.url_login_redirect(redirect_url, 'code')
  end

  def url_logout_redirect
    client.verify_setup

    a = Addressable::URI.parse client.configuration['end_session_endpoint']
    a.query_values = { redirect_uri: system_login_url }
    a.to_s
  end

  def user_info_by_token(access_token)
    # success
    # {
    #  "user-groups"=>["merchant"],
    #  "sub"=>"bb79fd25-1971-441b-96b3-082f439c7a59",
    #  "email_verified"=>true,
    #  "preferred_username"=>"site-builder-merchant@sdk.finance",
    #  "email"=>"site-builder-merchant@sdk.finance"
    # }
    # error
    # {
    #   "error"=>"invalid_token",
    #   "error_description"=> "Token verification failed"
    # }
    response = JSON.parse client.get_userinfo(access_token['access_token'])

    raise MerchantlyKeycloak::ResponseError.new(response) if response['error'].present?

    response
  rescue RestClient::BadRequest, RestClient::Unauthorized => e
    response = JSON.parse e.response.to_s

    raise MerchantlyKeycloak::ResponseError.new(response)
  end

  def access_token_by_code(code)
    # success
    # {
    #  "access_token"=> "...",
    #  "expires_in"=>300,
    #  "refresh_expires_in"=>1800,
    #  "refresh_token"=> "...",
    #  "token_type"=>"bearer",
    #  "not-before-policy"=>1596529970,
    #  "session_state"=>"0dd84abb-3223-4709-9228-0b7f82fad4b8",
    #  "scope"=>"profile email"
    # }
    # error
    # {
    # "error":"invalid_grant",
    # "error_description":"Code not valid"
    # }
    response = JSON.parse client.get_token_by_code(code, redirect_url)

    raise MerchantlyKeycloak::ResponseError.new(response) if response['error'].present?

    response
  rescue RestClient::BadRequest => e
    response = JSON.parse e.response.to_s

    raise MerchantlyKeycloak::ResponseError.new(response)
  end

  def refresh_token(access_token)
    response = JSON.parse client.get_token_by_refresh_token(access_token['refresh_token'])

    raise MerchantlyKeycloak::ResponseError.new(response) if response['error'].present?

    response
  rescue RestClient::BadRequest => e
    response = JSON.parse e.response.to_s

    raise MerchantlyKeycloak::ResponseError.new(response)
  end

  private

  def client
    @client ||= Keycloak::Client
  end

  def redirect_url
    system_keycloak_sign_in_url
  end
end
