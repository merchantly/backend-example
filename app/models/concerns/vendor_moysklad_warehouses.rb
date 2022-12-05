module VendorMoyskladWarehouses
  extend ActiveSupport::Concern

  def moysklad_warehouses
    warehouses.with_source(:moysklad)
  end

  def use_all_moysklad_warehouses?
    moysklad_warehouses.alive.pluck(:is_active).inject(:&)
  end
end
