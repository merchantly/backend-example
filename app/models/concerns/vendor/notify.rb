module Vendor::Notify
  def notify(message, subject: nil)
    VendorNotificationService.new(self)
      .notify_owners(
        mail_subject: subject || message,
        mail_text: message,
        sms_text: message
      )
  end
end
