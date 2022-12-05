class Reporters::SalesChart < Reporters::SalesBase
  def perform(type, locale = I18n.locale)
    data = case filter.period
           when ReportsFilter::DAILY_PERIOD
              order_items.group_by_hour_of_day(:created_at, format: '%-l %P', range: filter.from..filter.to, locale: locale)
           when ReportsFilter::WEEKLY_PERIOD, ReportsFilter::MONTHLY_PERIOD, ReportsFilter::CUSTOM_PERIOD
              order_items.group_by_day(:created_at, format: '%e %B %Y', range: filter.from..filter.to, locale: locale)
           else
              raise "Unknown #{filter.period}"
           end

    case type.to_sym
    when :grossing
      data.sum('orders.total_price_cents').transform_values { |cents| Money.new cents, vendor.default_currency }
    when :selling
      data.count(:order_id)
    else
      raise "Unknown type #{type}"
    end
  end
end
