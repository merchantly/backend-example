class ChartService
  include Virtus.model

  attribute :period, Integer

  def period
    super.seconds
  end

  def chart_selling_vendors
    [
      { name: I18n.t('system.chart.selling_vendors.month'), data: sale_graph_entities_month },
      { name: I18n.t('system.chart.selling_vendors.week'), data: sale_graph_entities_week }
    ]
  end

  def chart_vendors
    [
      { name: I18n.t('system.chart.vendors'), data: vendors }
    ]
  end

  def chart_orders
    [
      { name: I18n.t('system.chart.orders.all'), data: orders },
      { name: I18n.t('system.chart.orders.paid'), data: success_orders }
    ]
  end

  def chart_payments
    [
      { name: I18n.t('system.chart.payments'), data: success_payments }
    ]
  end

  def vendor_cellers_count
    vendor_cellers.count(:id)
  end

  def monthly_active_vendor_cellers_count
    vendor_cellers.where('order_payments.updated_at >= ?', DateTime.current - 1.month).order(id: :asc).count(:id)
  end

  def weekly_active_vendor_cellers_count
    vendor_cellers.where('order_payments.updated_at >= ?', DateTime.current - 1.week).order(id: :asc).count(:id)
  end

  def weekly_average_order_amount
    count = weekly_orders.count
    return Money.new(0) if count.zero?

    weekly_orders_summ / count
  end

  def weekly_orders_summ
    @weekly_orders_summ ||= begin
                              total = weekly_orders.map(&:total_with_delivery_price).sum

                              total.zero? ? Money.new(0) : total
    end
  end

  def weekly_payments_summ
    ids = vendor_cellers.where('order_payments.updated_at >= ?', DateTime.current - 1.week).pluck(:order_id)

    total = Order.where(id: ids).map(&:total_with_delivery_price).sum

    total.zero? ? Money.new(0) : total
  end

  def monthly_average_order_amount
    count = monthly_orders.count
    return Money.new(0) if count.zero?

    monthly_orders_summ / count
  end

  def monthly_orders_summ
    @monthly_orders_summ ||= begin
                               total = monthly_orders.map(&:total_with_delivery_price).sum
                               total.zero? ? Money.new(0) : total
    end
  end

  def monthly_payments_summ
    ids = vendor_cellers.where('order_payments.updated_at >= ?', DateTime.current - 1.month).pluck(:order_id)

    total = Order.where(id: ids).map(&:total_with_delivery_price).sum

    total.zero? ? Money.new(0) : total
  end

  private

  def monthly_orders
    Order.where('created_at >= ?', DateTime.current - 1.month)
  end

  def weekly_orders
    Order.where('created_at >= ?', DateTime.current - 1.week)
  end

  def vendor_cellers
    Vendor.joins(orders: :order_payment).where(order_payments: { state: 'paid' }).distinct
  end

  def orders
    grouping do |past_time, current_time|
      Order.where('created_at >= ? AND created_at <= ?', past_time, current_time).count
    end.sort.to_h
  end

  def success_orders
    grouping do |past_time, current_time|
      Order.success.where('orders.created_at >= ? AND orders.created_at <= ?', past_time, current_time).count
    end.sort.to_h
  end

  def success_payments
    grouping do |past_time, current_time|
      OrderPayment.success.joins(:order).where('order_payments.created_at >= ? AND order_payments.created_at <= ?', past_time, current_time).sum('total_with_delivery_price_cents') / 100
    end
  end

  def vendors
    grouping do |past_time, current_time|
      Vendor.where('created_at >= ? AND created_at <= ?', past_time, current_time).count
    end.sort.to_h
  end

  def sale_graph_entities_month
    sale_graph_entities.pluck(:date, :selling_vendors_month).to_h
  end

  def sale_graph_entities_week
    sale_graph_entities.pluck(:date, :selling_vendors_week).to_h
  end

  def sale_graph_entities
    SaleGraphEntity.ordered.where('date >= ?', Date.current - period)
  end

  def grouping
    result = {}
    current_time = DateTime.current.beginning_of_week
    past_time = current_time - interval

    (period / interval).times do
      key = current_time.strftime '%F %H:%M:%S UTC'

      result[key] = yield(past_time.beginning_of_day, current_time.end_of_day)
      current_time = past_time
      past_time = current_time - interval
    end

    result
  end

  def interval
    period > 1.month ? 1.week : 1.day
  end
end
