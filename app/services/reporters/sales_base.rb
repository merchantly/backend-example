class Reporters::SalesBase
  def initialize(vendor, filter = nil, page = nil, per = nil)
    @vendor = vendor
    @filter = filter
    @page = page
    @per = per
  end

  private

  attr_reader :vendor, :filter, :page, :per

  def order_items
    @order_items ||= build_order_items
  end

  def build_order_items
    scope = vendor.order_items.payed

    if filter.present?
      scope = scope.where('orders.created_at >= ? ', filter.from_date) if filter.from_date.present?
      scope = scope.where('orders.created_at < ?', filter.till_date) if filter.till_date.present?
    end

    scope = scope.page(page).per(per) if per.present?

    scope
  end
end
