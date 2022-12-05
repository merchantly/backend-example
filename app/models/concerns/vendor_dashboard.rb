module VendorDashboard
  extend ActiveSupport::Concern

  def dashboard_item_checked?(item)
    checked_dashboard_items.include? item.key
  end

  def check_dashboard_item!(key)
    new_items = checked_dashboard_items << key
    update_column :checked_dashboard_items, new_items.uniq
  end

  def unchecked_dashboard_items_count
    DashboardItem.all.reject { |i| dashboard_item_checked? i }.count
  end

  def uncheck_dashboard_item!(key)
    new_items = checked_dashboard_items - [key]
    update_column :checked_dashboard_items, new_items
  end
end
