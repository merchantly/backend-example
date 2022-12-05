# concern для логирования съема средств
module Billing::ChargeLogging
  private

  def create_charge_log
    raise 'No payment_account method' unless respond_to? :payment_account
    raise 'No invoice method' unless respond_to? :invoice

    invoice.charges.create! payment_account: payment_account
  end

  def log_charge(message, state: nil)
    message ||= state
    Billing.logger.debug "ChargeLog: [#{state}, #{charge_log_entity.id}, #{invoice.id}, #{invoice.amount}, #{payment_account}]: #{message}"
    charge_log_entity.update_attribute :result, message
    payment_account.update state: state, last_result: message if state.present?
  end

  def charge_log_entity
    @charge_log_entity ||= create_charge_log
  end
end
