class TitleLiquidRenderer
  RESOURCES = %w[
    content_pages
    dictionary_entities
    dictionaries
    lookbooks
    products
    vendors
    blog_posts
    categories
  ].freeze

  def initialize(template:, vendor:)
    @template = template
    @vendor = vendor
  end

  def render(resource)
    liquid_template = Liquid::Template.parse @template, error_mode: :strict
    liquid_template.render({ 'resource' => resource.to_liquid, 'vendor' => @vendor.to_liquid }, strict_variables: true)
  rescue Liquid::ArgumentError, Liquid::SyntaxError => e
    Bugsnag.notify e do |b|
      b.meta_data = { resource: resource.class.name, resource_id: resource.try(:id), vendor_id: @vendor.id }
    end
    e.message
  end
end
