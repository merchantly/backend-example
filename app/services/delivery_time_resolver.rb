class DeliveryTimeResolver
  DEFAULT_TIME_SLOTS_LIMIT = 14

  def self.perform(vendor_delivery:, current_time:)
    return unless vendor_delivery.delivery_time_periods.actual(current_time).exists?

    rule = vendor_delivery.delivery_time_rules.ordered.where('delivery_time_rules.to > ? AND is_default IS NOT TRUE', current_time.time).first

    rule = vendor_delivery.default_delivery_time_rule if rule.blank?

    current_time += rule.days_count.days

    datetime = current_time.change(hour: rule.time.hour, min: rule.time.min)

    vendor_delivery.delivery_time_periods.where('from_at >= ?', datetime.time).ordered.limit(vendor_delivery.delivery_time_slots_limit || DEFAULT_TIME_SLOTS_LIMIT)
  rescue StandardError => e
    Bugsnag.notify e

    nil
  end
end
