class OperatorOrdersFrontFilter < OperatorBaseFrontFilter
  FILTER_KEYS = %i[workflow_state_id has_reserved_items delivery_state payment_state delivery_type_id payment_type_id coupon_id source refund].freeze

  attribute :vendor, Vendor
  attribute :filter, VendorOrdersFilter

  def render
    filter_keys.map do |key|
      filter_selector key
    end.join("\n").html_safe
  end

  def filter_keys
    @filter_keys ||= build_filter_keys
  end

  def build_filter_keys
    keys = FILTER_KEYS
    keys -= %i[source refund] unless IntegrationModules.enable?(:ecr)
    keys
  end

  private

  def enums
    @enums ||= build_enums
  end

  def build_enums
    {
      workflow_state_id: vendor.workflow_states.alive.ordered.to_a,
      payment_type_id: vendor.available_payment_types.to_a,
      delivery_type_id: vendor.available_delivery_types.to_a,
      delivery_state: OrderDelivery::STATES,
      payment_state: OrderPayment::STATES,
      coupon_id: vendor.coupons.base.ordered.to_a,
      source: OrderSource::SOURCES,
      refund: OrderRefund::SCOPES
    }
  end

  def filter_link(key, value)
    link_to Rails.application.routes.url_helpers.operator_orders_path(filter.exclude(:page).merge(key => value)) do
      i18n_filter_value(key, value)
    end
  end

  def i18n_filter_name(key)
    I18n.t :name, scope: [:filters, :orders, key]
  end

  def i18n_filter_value(field, value)
    if filter.is_record?(field) && value.present?
      filter.record field, value
    else
      I18n.t i18n_key(value), scope: [:filters, :orders, field, :values]
    end
  end
end
