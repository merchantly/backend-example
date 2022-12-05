class OperatorClientsFrontFilter < OperatorBaseFrontFilter
  FILTER_KEYS = %i[name address phone email].freeze

  attribute :filter, VendorClientsFilter

  def render
    filter_keys.map do |key|
      filter_selector key
    end.join("\n").html_safe
  end

  def filter_keys
    @filter_keys ||= build_filter_keys
  end

  private

  def build_filter_keys
    FILTER_KEYS
  end

  def enums
    @enums ||= {}
  end

  def filter_link(key, value)
    link_to Rails.application.routes.url_helpers.operator_products_path(filter.exclude(:page).merge(key => value)) do
      i18n_filter_value(key, value)
    end
  end

  def i18n_filter_name(key)
    I18n.t :name, scope: [:filters, :clients, key]
  end

  def i18n_filter_value(_field, value)
    value
  end
end
