class VendorEmail < ApplicationRecord
  belongs_to :vendor

  validates :email, email: { mx_with_fallback: true, ban_disposable_email: true }, if: :email_and_changed?
  validate :check_forbidden_emails

  before_save :check

  def check!
    check
    save! if changed?
  end

  def check
    if email.present?
      result = Coppertone::SpfService.authenticate_app_email email

      self.is_active = result.pass?
      self.last_checkup_at = Time.zone.now
      self.last_checkup_result = result.to_json
    else
      self.is_active = false
      self.last_checkup_result = nil
      self.last_checkup_at = nil
    end
  end

  private

  def email_and_changed?
    will_save_change_to_email? && email?
  end

  def check_forbidden_emails
    downcase_email = email.downcase

    Settings.domain_zones.each do |domain|
      return errors.add(:email, 'Wrong domain') if downcase_email.end_with?(domain)
    end
  end
end
