require 'securerandom'
class Invite < ApplicationRecord
  include Authority::Abilities
  include PhoneAndEmail
  include InviteActivation
  include InviteSends
  include DisableUpdate
  include MemberRoles

  belongs_to :operator_inviter, class_name: 'Operator'
  belongs_to :vendor

  validates :role, presence: true
  validate :validate_role

  validates :name, presence: true
  validates :phone, phone: true, uniqueness: { scope: :vendor_id }, allow_blank: true
  validates :email, email: true, uniqueness: { scope: :vendor_id }, allow_blank: true

  scope :by_operator, lambda { |operator|
    if operator.phone.present? && operator.email.present?
      where 'phone=? or email=? or key=?', operator.phone, operator.email, operator.invite_key
    elsif operator.phone.present?
      where 'phone=? or key=?', operator.phone, operator.invite_key
    elsif operator.email.present?
      where 'email=? or key=?', operator.email, operator.invite_key
    else
      Invite.none
    end
  }

  scope :ordered, -> { order :id }

  before_create do
    self.key = SecureRandom.hex(5)
  end

  def url
    Rails.application.routes.url_helpers.new_system_operator_url invite_key: key
  end

  private

  def validate_role
    errors.add(:base, 'Invalid role') if vendor.roles.owner.id == role_id
  end
end
