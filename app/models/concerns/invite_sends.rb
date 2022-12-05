module InviteSends
  extend ActiveSupport::Concern

  included do
    after_commit :send_invite, on: :create
  end

  private

  def send_invite
    send_email if email.present?
    send_sms if phone.present?
  end

  def send_sms
    SmsWorker.perform_async phone, I18n.t('services.invite.sms_text', url: url, vendor: vendor.host)
  end

  def send_email
    OperatorMailer.new_invite(id).deliver_later!
  end
end
