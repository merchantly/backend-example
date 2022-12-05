class Member < ApplicationRecord
  include Authority::Abilities
  include Authority::UserAbilities
  include MemberRoles
  include AttachUserRequests

  belongs_to :vendor
  belongs_to :operator
  has_many :orders

  has_one :vendor_bitrix24, foreign_key: :responsible_manager_id, dependent: :nullify

  has_many :carts, dependent: :destroy

  scope :ordered, -> { order :id }
  scope :by_operator, ->(operator) { where operator_id: operator.id }
  scope :by_token,    ->(token) { where token: token }

  scope :with_phone,  ->(phone) { joins(:operator).where(operators: { phone: phone }) }
  scope :with_email,  ->(email) { joins(:operator).where(operators: { email: email }) }

  scope :with_sms_notification, -> { joins(:operator).where.not(operators: { phone_confirmed_at: nil }).where(sms_notification: true) }
  scope :with_email_notification, -> { joins(:operator).where.not(operators: { email_confirmed_at: nil }).where(email_notification: true) }

  scope :owner, -> { joins(:role, :operator).where(roles: { key: Role::OWNER }) }

  validates :operator_id, uniqueness: { scope: :vendor_id }
  validates :pin_code, uniqueness: { scope: :vendor_id }

  delegate :name, :phone, :email, :detail, :is_super_admin?, to: :operator

  before_create do
    self.token = SecureRandom.hex 32
    self.api_access_key = SecureRandom.hex 32
    self.pin_code = generate_pin_code
  end

  after_commit :send_pin_code, on: :create if Settings::Features.member_send_pin_code

  def to_s
    name
  end

  def self.set_tokens
    where(token: '').find_each do |member|
      member.update_column :token, SecureRandom.hex(32)
    end
  end

  def touch_last_signed_at
    transaction do
      touch :last_signed_at if persisted?
      operator.touch :last_signed_at
      vendor.touch :last_signed_at
    end
  end

  def generate_pin_code
    loop do
      pin_code = (0..3).map { rand(1..9).to_s }.join

      return pin_code unless vendor.members.exists?(pin_code: pin_code)
    end
  end

  def regenerate_pin_code!
    update_columns pin_code: generate_pin_code, generate_pin_code_at: Time.zone.now

    send_pin_code
  end

  def send_pin_code
    OperatorMailer.pin_code(id).deliver! if email.present?
  end
end
