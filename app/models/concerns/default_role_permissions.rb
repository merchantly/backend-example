module DefaultRolePermissions
  VALUES = {
    # Add item – да
    # Edit item – да
    # Cancel discount – да
    # Payment terminal settings – нет
    # Refund – да
    # Open and Close drawer – да
    # Customer Creation – да
    Role::SELLER => [
      {
        resource_type: 'Product',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true
      },
      {
        resource_type: 'ProductItem',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true
      },
      {
        resource_type: 'Client',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true,
      },
      {
        resource_type: 'Ecr::Drawer',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true
      },
      {
        resource_type: 'Order',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true
      }
    ],
    # Add item – нет
    # Edit item – нет
    # Cancel discount – да
    # Payment terminal settings – нет
    # Refund – нет
    # Open and Close drawer – да
    # Customer Creation – да
    Role::CASHIER => [
      {
        resource_type: 'Client',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true,
      },
      {
        resource_type: 'Ecr::Drawer',
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: true
      }
    ],
  }.freeze
end
