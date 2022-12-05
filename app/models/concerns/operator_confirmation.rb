module OperatorConfirmation
  extend ActiveSupport::Concern

  included do
    before_save :clear_is_delivery_email

    before_save :require_email_confirmation,  if: :will_save_change_to_email? if Settings::Features.operator_require_email_confirmation
    before_save :require_phone_confirmation,  if: :will_save_change_to_phone? if Settings::Features.operator_require_phone_confirmation

    after_commit :deliver_email_confirmation!, on: %i[create update], if: :is_delivery_email
  end

  def one_of_confirmed_phones?(phone)
    phone_confirmations.by_phone(phone).confirmed.exists?
  end

  def phone_confirmed?
    phone_confirmed_at.present?
  end

  def phone_confirmation_for_phone(some_phone = nil)
    phone_confirmations.find_or_create_by! phone: (some_phone.presence || phone)
  end

  def confirm_some_phone!(phone, pin_code)
    phone_confirmations.by_phone(phone).not_confirmed.each do |pc|
      pc.confirm pin_code
    end
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_phone_if_need!(confirm_phone)
    confirm_phone! if confirm_phone == phone
  end

  def confirm_phone!
    return if phone_confirmed?

    update_column :phone_confirmed_at, Time.zone.now
  end

  def confirm_email!
    return if email_confirmed?

    update_columns email_confirmed_at: Time.zone.now
  end

  def email_confirmation_url
    Rails.application.routes.url_helpers
         .system_email_confirmation_url token: email_confirm_token
  end

  def deliver_email_confirmation!
    @is_delivery_email = false

    OperatorMailer.email_confirmation(id).deliver if Rails.env.production?
  end

  private

  def require_phone_confirmation
    pc = phone_confirmations.by_phone(phone).first

    if pc.present?
      self.phone_confirmed_at = pc.confirmed_at
    else
      phone_confirmations.build phone: phone if phone.present?
      self.phone_confirmed_at = nil
    end
  end

  def require_email_confirmation
    self.email_confirmed_at = nil
    if email.present?
      self.email_confirm_token = Sorcery::Model::TemporaryToken.generate_random_token
      @is_delivery_email = true
    end
  end

  def is_delivery_email
    @is_delivery_email
  end

  def clear_is_delivery_email
    @is_delivery_email = false
    true
  end
end
