module PhoneAndEmail
  extend ActiveSupport::Concern

  included do
    strip_attributes

    scope :by_email, ->(email) { where email: email.to_s.downcase }
    scope :by_phone, ->(phone) { where phone: PhoneUtils.clean_phone(phone) }

    validates :email, presence: true, if: :require_email?
    validates :email, email: true, uniqueness: true, allow_blank: true, if: :uniqueness_phone_and_email?

    validates :phone, presence: true, if: :require_phone?
    validates :phone, phone: true, uniqueness: true, allow_blank: true, if: :uniqueness_phone_and_email?
  end

  def phone=(value)
    if value.present?
      super PhoneUtils.clean_phone value
    else
      super value
    end
  end

  def email=(value)
    if value.present?
      super value.downcase
    else
      super value
    end
  end

  private

  def uniqueness_phone_and_email?
    return false unless is_operator?

    !IntegrationModules.enable?(:keycloak)
  end

  def require_phone?
    return false if (is_operator? && IntegrationModules.enable?(:keycloak)) || is_invite?

    email.blank?
  end

  def require_email?
    return false if is_operator? && IntegrationModules.enable?(:keycloak)
    return true if is_invite? && IntegrationModules.enable?(:ecr)

    phone.blank?
  end

  def is_operator?
    instance_of?(Operator)
  end

  def is_invite?
    instance_of?(Invite)
  end
end
