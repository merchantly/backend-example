module VendorRoles
  extend ActiveSupport::Concern
  included do
    after_create :create_default_roles!
  end

  private

  def create_default_roles!
    default_roles.each do |default_role|
      next if roles.exists? key: default_role

      role = Role.create!(
        title_translations: HstoreTranslate.translations(default_role, %i[enumerize member role]),
        key: default_role,
        vendor_id: id
      )

      permissions = DefaultRolePermissions::VALUES[role.key.to_sym]

      next if permissions.blank?

      permissions.each do |permission|
        role.permissions.create!(
          resource_type: permission[:resource_type],
          can_read: permission[:can_read],
          can_create: permission[:can_create],
          can_update: permission[:can_update],
          can_delete: permission[:can_delete]
        )
      end
    end
  end

  def default_roles
    if IntegrationModules.enable?(:ecr)
      Role::DEFAULT_ROLES + Role::ECR_DEFAULT_ROLES
    else
      Role::DEFAULT_ROLES
    end
  end
end
