module MemberRoles
  extend ActiveSupport::Concern

  included do
    belongs_to :role

    before_validation :set_default_role
  end

  def admin?
    operator.is_super_admin? || role.owner? || role.manager?
  end

  def invited?
    !role.owner?
  end

  %i[can_read can_create can_update can_delete].each do |method_name|
    define_method "role_#{method_name}?" do |resource_or_class|
      resource_type = resource_or_class.is_a?(Class) ? resource_or_class.name : resource_or_class.class.name

      return true if resource_type == OperatorDashboardBuilder.name

      role.permissions.by_resource_type(resource_type).try("#{method_name}?")
    end
  end

  private

  def set_default_role
    return if vendor.blank?

    self.role = vendor.roles.find_by(key: Role::DEFAULT_ROLE) if role.blank?
  end
end
