class MerchantlyKeycloak::SignInChecker
  include Sidekiq::Worker
  sidekiq_options queue: :critical

  def perform(operator_id)
    operator = Operator.find operator_id

    return if !operator.keycloak_signed_in? || operator.keycloak_access_token.nil?

    access_token = authenticator.refresh_token(operator.keycloak_access_token)

    operator.update!(
      keycloak_signed_in: true,
      keycloak_access_token: access_token,
      keycloak_last_check_at: Time.zone.now
    )
  rescue MerchantlyKeycloak::ResponseError => e
    Bugsnag.notify(e)

    operator.update!(
      keycloak_signed_in: false,
      keycloak_access_token: nil,
      keycloak_last_check_at: Time.zone.now
    )
  end

  private

  def authenticator
    @authenticator ||= MerchantlyKeycloak::Authenticator.new
  end
end
