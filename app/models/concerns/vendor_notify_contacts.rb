module VendorNotifyContacts
  extend ActiveSupport::Concern
  include SeparatedList

  def contacts_array
    parse_separated_list contacts
    # ['+7 909 662 4242',"+7 495 999 7939"]
  end

  def order_notification_emails_array
    members.with_email_notification.pluck(:email).compact.uniq
  end

  def order_notification_phones_array
    members.with_sms_notification.pluck(:phone).compact.uniq
  end

  def owner_phones_array
    members.owner.pluck(:phone).compact.uniq
  end

  def owner_emails_array
    members.owner.pluck(:email).compact.uniq
  end

  def phone
    order_notification_phones_array.first
  end

  def notify(message, subject: nil)
    VendorNotificationService.new(self)
      .notify_owners(
        mail_subject: subject || message,
        mail_text: message,
        sms_text: message
      )
  end
end
