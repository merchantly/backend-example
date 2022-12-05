class VendorWalletone < ApplicationRecord
  extend Enumerize

  UncompleteProfile = Class.new StandardError
  UnconfirmedPhone  = Class.new StandardError
  STATE_LEGACY       = 'legacy'.freeze
  STATE_NOT_APPROVED = 'not_approved'.freeze
  STATE_APPROVED     = 'approved'.freeze
  STATE_ERROR_APPROVING = 'error'.freeze

  TYPE_UNKNOWN       = 'unknown'.freeze
  TYPE_PERSONAL      = 'personal'.freeze
  TYPE_BUSINESS      = 'business'.freeze

  belongs_to :vendor
  belongs_to :branch_category, counter_cache: :shops_count
  belongs_to :phone_operator, class_name: 'Operator'

  scope :not_confirmed_phone, -> { where(phone_confirmed_at: nil) }

  enumerize :legal_form,
            in: [TYPE_UNKNOWN, TYPE_PERSONAL, TYPE_BUSINESS],
            default: TYPE_UNKNOWN,
            predicates: { prefix: true }

  enumerize :state,
            in: [STATE_LEGACY, STATE_NOT_APPROVED, STATE_APPROVED, STATE_ERROR_APPROVING],
            default: STATE_NOT_APPROVED,
            predicates: { prefix: true }

  before_save :unconfirm_phone_if_need

  def on?
    state_approved? || (state_legacy? && merchant_id.present? && merchant_sign_key.present?)
  end

  def complete?
    validate_complete!
    true
  rescue UncompleteProfile
    false
  end

  def full_name
    [first_name, middle_name, last_name].compact.join ' '
  end

  def fields
    attrs = %w[title branch_category
               first_name middle_name last_name
               phone phone_confirmed? email currency_id]

    attrs += %w[legal_country legal_title legal_tax_number legal_address legal_reg_number] if legal_form_business?

    attrs
  end

  def validate_complete!
    blank_list = []
    fields.each do |a|
      blank_list << a if send(a).blank?
    end
    blank_list << 'legal_form' if legal_form_unknown?

    raise UncompleteProfile, blank_list if blank_list.present?
    raise UnconfirmedPhone unless phone_confirmed?
  end

  def to_s
    "#{title} #{merchant_id}"
  end

  def phone_confirmed=(value)
    if value.present?
      super PhoneUtils.clean_phone value
    else
      super value
    end
  end

  def phone=(value)
    if value.present?
      super PhoneUtils.clean_phone value
    else
      super value
    end
  end

  def url
    vendor.public_url
  end

  def result_url
    vendor.w1_payment_callback_url
  end

  def promo_code
    Settings.w1.promo_codes[legal_form]
  end

  def confirm_phone_if_need!(confirm_phone, operator)
    return if phone.present? && confirm_phone != phone

    update! phone_confirmed_at: Time.zone.now, phone_operator: operator, phone_confirmed: confirm_phone, phone: confirm_phone
  end

  def phone_confirmed?
    phone_confirmed == phone && phone_confirmed_at.present?
  end

  def approve!
    return unless merchant_id? && merchant_sign_key? && merchant_token?

    vendor.check_dashboard_item! :payment
    update_column :state, STATE_APPROVED
  end

  def error_approving!
    update_column :state, STATE_ERROR_APPROVING
  end

  def self.legal_country_options
    Settings.w1.legal_country_options.invert
  end

  private

  def unconfirm_phone_if_need
    self.phone_confirmed_at = nil unless phone == phone_confirmed
  end
end
