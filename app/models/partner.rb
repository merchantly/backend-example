class Partner < ApplicationRecord
  include ::Partner::AccountBilling

  MAX_AUTO_COUPON_LENGTH = 6

  validates :name, presence: true
  belongs_to :operator
  has_many :coupons, dependent: :destroy
  has_many :vendors, through: :coupons

  delegate :count, to: :vendors, prefix: true
  delegate :count, to: :coupons, prefix: true

  delegate :phone, :email, :locale, to: :operator, allow_nil: true

  after_commit :generate_default_coupon!, on: :create
  after_commit :send_registration_letter, on: :create

  def generate_default_coupon!
    return if coupons.default.exists?

    coupons.create! code: SecureRandom.hex.first(MAX_AUTO_COUPON_LENGTH), is_default: true
  rescue ActiveRecord::RecordInvalid # Coupon code are not unique
    retry
  end

  private

  def send_registration_letter
    return if email.blank?

    OperatorMailer.partner_registration(id).deliver!

    update_column :registration_letter_send_at, Time.zone.now
  end
end
