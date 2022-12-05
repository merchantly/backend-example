class OperatorProductsFrontFilter < OperatorBaseFrontFilter
  FILTER_KEYS = %i[is_published
                   has_ordering_goods
                   property_id
                   product_type
                   is_run_out
                   is_sale
                   has_price has_images has_items
                   is_stock_linked].freeze

  attribute :filter, VendorProductsFilter

  def render
    filter_keys.map do |key|
      filter_selector key
    end.join("\n").html_safe
  end

  def open?
    filter.exclude(:category_id, :query, :page, :per_page).any?
  end

  def filter_keys
    @filter_keys ||= build_filter_keys
  end

  private

  def build_filter_keys
    keys = FILTER_KEYS
    keys -= [:is_stock_linked] unless IntegrationModules.enable?(:moysklad)
    keys -= [:product_type] unless Settings::Features.products_filter.product_type
    keys
  end

  def enums
    @enums ||= {
      product_type: %w[union separate],
      # quanting:     VendorProductsFilter::QUANTITIES,
      availability: VendorProductsFilter::AVAILABILITIES
    }
  end

  def filter_link(key, value)
    link_to Rails.application.routes.url_helpers.operator_products_path(filter.exclude(:page).merge(key => value)) do
      i18n_filter_value(key, value)
    end
  end

  def i18n_filter_name(key)
    I18n.t :name, scope: [:filters, :products, key]
  end

  def i18n_filter_value(field, value)
    if filter.is_record?(field) && value.present?
      filter.record field, value
    elsif field == :dictionary_entity_ids
      value.join(', ')
    else
      I18n.t i18n_key(value), scope: [:filters, :products, field, :values]
    end
  end
end
