module VendorEcrWarehouses
  extend ActiveSupport::Concern

  included do
    if IntegrationModules.enable?(:ecr)
      after_create :create_default_warehouse!
    end
  end

  def ecr_warehouses
    warehouses.with_source(:ecr)
  end

  def create_default_warehouse!
    warehouse = warehouses.create! name: I18n.t(:default, scope: %i[titles warehouses]), source: :ecr

    update_column :default_warehouse_id, warehouse.id
  end
end
