class Slug < ApplicationRecord
  extend Enumerize
  include FixPath
  include Authority::Abilities

  FORBIDDEN_PATHS = (%w[/ /cart /order] + I18n.available_locales.map { |l| "/#{l}" }).freeze

  belongs_to :vendor
  belongs_to :resource, polymorphic: true

  has_one :history_path, foreign_key: :path, primary_key: :path

  scope :ordered,   -> { order :path }
  scope :redirects, -> { where type: 'SlugRedirect' }
  scope :by_query,  ->(path) { where 'path ilike ? or redirect_path ilike ?', "%#{path}%", "%#{path}%" }
  # найдет '/categories/' если передать '/categories' и наоборот
  scope :by_path,   ->(path) { where 'path = ? OR path = ?', path.gsub(/\/$/, ''), "#{path.gsub(/\/$/, '')}/" }

  before_validation :fix_slug_path

  validates :path,
            presence: true,
            format: { without: /[.]/, message: 'Точки использовать нельзя' },
            uri_component: { component: :ABS_PATH },
            exclusion: { in: FORBIDDEN_PATHS }

  before_save :fix_slug_path, :update_product_cached_public_url

  after_save :mark_history_path

  validate :validate_unique_path

  def path=(value)
    if value.blank?
      mark_for_destruction
    else
      super
    end
  end

  def to_s
    path
  end

  def alive?
    true
  end

  def default_path
    return path if I18n.locale.to_s == vendor.default_locale

    "/#{I18n.locale}#{path}"
  end

  private

  def mark_history_path
    history_path.update_attribute :state, :slugged if history_path.present?
  end

  def fix_slug_path
    self.path = fix_path path
  end

  def update_product_cached_public_url
    return unless resource_type == 'Product'

    resource.update_cached_public_url
  end

  def validate_unique_path
    slug = vendor.slugs.where.not(id: id).find_by(path: path)

    return if slug.blank?

    errors.add :path, I18n.t('errors.slug.not_unique_path', resource_path: operator_slug_resource_path(slug)).html_safe
  end

  def operator_slug_resource_path(slug)
    resource = slug.resource.presence || slug

    edit_path = case resource
                when BlogPost
                  :edit_operator_blog_post_path
                when Category
                  :edit_operator_category_path
                when ContentPage
                  :edit_operator_content_page_path
                when Dictionary
                  :edit_operator_dictionary_path
                when DictionaryEntity
                  :edit_operator_dictionary_entity_path
                when Lookbook
                  :edit_operator_lookbook_path
                when Product
                  :edit_operator_product_path
                when SlugRedirect
                  :edit_operator_slug_redirect_path
                else
                  raise "Unknown #{resource.class}"
                end

    Rails.application.routes.url_helpers.send(edit_path, resource)
  end
end
