class OperatorBaseFrontFilter
  include CurrentVendor
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include ArbreHelper
  include Virtus.model

  def exists?
    filter.exclude(:page, :per_page).any?
  end

  def title_for(key)
    value = filter[key]
    title = []

    title << i18n_filter_name(key)
    title << (": #{i18n_filter_value(key, value)}") unless value.nil? || value == true

    title.join
  end

  def collection_for_select(key)
    raise 'no key' if key.blank?

    variants = variants_from_filter_key key
    raise 'no variants' if variants.blank?

    variants.map do |variant|
      [i18n_filter_value(key, variant), variant.to_param.to_s]
    end
  end

  def value_for(key)
    filter[key].to_s
  end

  private

  def variants_from_filter_key(key)
    if key.to_s.starts_with?('is_') || key.to_s.starts_with?('has_')
      [true, false, nil]
    elsif enums.key?(key)
      enums[key] + [nil]
    elsif key.to_s.ends_with?('_id')
      [nil]
    else
      auto_variant(key)
    end
  end

  def filter_selector(key)
    raise 'no key' if key.blank?

    variants = variants_from_filter_key key
    raise 'no variants' if variants.blank?

    value = filter[key]

    variants = variants.map do |v|
      { active?: value.to_s == v.to_param, link: filter_link(key, v) }
    end
    selector_class = 'btn-group m-b-xs m-r-xs m-t-xs'
    btn_class = if value.nil?
                  'btn-default btn-sm btn-outline'
                else
                  'btn-success btn-sm'
                end
    arbre do
      div class: selector_class do
        button type: :button, class: "btn #{btn_class} dropdown-toggle", 'data-toggle': :dropdown do
          span title_for(key)
          span class: 'caret'
        end
        ul class: 'dropdown-menu', role: :menu do
          variants.each do |v|
            li v[:link], class: v[:active?] ? 'active' : ''
          end
        end
      end
    end
  end

  def auto_variant(key)
    [key]
  end

  def i18n_key(value)
    key = value.nil? ? filter.class::ANY_VALUE : value
    key.to_s
  end
end
