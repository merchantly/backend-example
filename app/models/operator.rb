class Operator < ApplicationRecord
  # Вызывать до OperatorPassword, потому что в нем переопределяются valid_password?
  authenticates_with_sorcery!
  include Authority::Abilities
  include OperatorPassword
  include OperatorInvitable
  include PhoneAndEmail
  include OperatorConfirmation
  include OperatorAccessKey
  extend OperatorAuthenticate

  # scope :omniauth_scope, ->(auth_hash) { where() }
  has_many :invites,           dependent: :delete_all, foreign_key: :operator_inviter_id
  has_many :authentications,   dependent: :delete_all, as: :authenticatable
  has_many :members,           dependent: :delete_all
  has_many :vendors,           through: :members
  has_many :vendor_walletones, through: :vendors
  has_many :admin_comments,    as: :author, class_name: 'ActiveAdmin::Comment', dependent: :nullify
  has_many :phone_confirmations, autosave: true, dependent: :delete_all
  has_one :partner
  has_many :coupons, through: :partner, class_name: 'Partner::Coupon'

  scope :ordered, -> { order :id }
  scope :owners,  -> { joins(members: :role).where(roles: { key: Role::OWNER }) }

  # получатели системных рассылок
  scope :system_mail_recipients, lambda { |type|
    joins(:members)
    .where('? = ANY(system_subscriptions)', type)
    .where('operators.email IS NOT NULL AND operators.email_confirmed_at IS NOT NULL')
    .group('operators.id')
  }

  validates :name, presence: true

  validates :password, confirmation: true

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_nil: true

  accepts_nested_attributes_for :members, allow_destroy: true

  def self.build_from_keycloak_info(user_info)
    operator_name = user_info['name'] || user_info['given_name'] || user_info['preferred_username']
    operator = Operator.new keycloak_user_id: user_info['sub'], email: user_info['email'], name: operator_name
    operator.keycloak_user_info = user_info

    operator
  end

  def self.build_from_invite(invite)
    operator = Operator.new
    operator.assign_attributes invite.attributes.slice('email', 'phone')
    operator.invite_key = invite.key

    operator
  end

  def self.find_by_keycloak_info(user_info)
    Operator.find_by(keycloak_user_id: user_info['sub'])
  end

  def is_subscribed?(subscription_type)
    system_subscriptions.include? subscription_type
  end

  def deliver_pin_code(phone)
    phone_confirmation_for_phone(phone).deliver_pin_code
  rescue PhoneConfirmation::RequestTimeout
    nil
  end

  def display_name
    [name, email, phone].compact.join('; ')
  end

  def vendors_count
    @vendors_count ||= vendors.count
  end

  def detail
    "#{name} #{email} #{phone}"
  end

  def key
    id
  end

  def available_vendors
    vendors
  end

  def vendor_names
    vendors.pluck(:name).join(',')
  end

  def to_s
    name
  end
end
