module Vendor::FromEmail
  def reply_to
    support_email
  end

  def vendor_email
    super || build_vendor_email
  end

  def email_from_name
    name
  end

  def internal_from_email
    Settings.vendor_internal_from_email || raise(Settingslogic::MissingSetting)
  rescue Settingslogic::MissingSetting
    "#{id}-#{Settings.vendor_mail_postfix}"
  end

  def from_email
    email = internal_from_email

    email = vendor_email.email if check_vendor_email

    ascii_email = SimpleIDN.to_ascii email

    address = Mail::Address.new ascii_email
    address.display_name = email_from_name
    address.format
  end

  def check_vendor_email
    return false unless Settings::Features.edit_vendor_email
    return false if vendor_email.email.blank?

    vendor_email.check!
    if vendor_email.is_active?

          return true if vendor_email.is_active?

          bells_handler.add_error :spf_check_fail, email: vendor_email.email

          false
    else

          vendor_email.is_active?
        end
  end
end
