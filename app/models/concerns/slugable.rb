module Slugable
  extend ActiveSupport::Concern

  included do
    has_one :slug,            as: :resource, class_name: 'SlugResource', dependent: :destroy
    has_many :slug_redirects, as: :resource, class_name: 'SlugRedirect', dependent: :destroy

    before_validation :prepare_slug
    accepts_nested_attributes_for :slug, allow_destroy: true
    before_save :cache_default_slug
  end

  module ClassMethods
    def find_by_slug(slug)
      find slug.to_s.split('-')[0].to_i
    end
  end

  def public_url(params = {})
    current_vendor.home_url + public_path(params)
  end

  def public_path(params = {})
    path = slug.present? && slug.persisted? ? slug.default_path : default_path
    return path if params.empty?

    "#{path}?#{params.to_query}"
  end

  def to_param
    [id.to_s, title_slug].compact.join '-'
  end

  def title_slug
    Slugger.slug_postfix title
  end

  def operator_path
    meth = "operator_#{self.class.name.underscore}_path"
    Rails.application.routes.url_helpers.send meth, to_param
  end

  private

  def cache_default_slug
    self.cached_default_slug = title_slug if self.class.attribute_names.include? 'cached_default_slug'
  end

  def prepare_slug
    if slug.present? && !slug.persisted? && !slug.marked_for_destruction?
      slug.vendor_id = vendor_id
      slug.resource  = self
    end
  end
end
