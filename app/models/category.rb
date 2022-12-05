class Category < ApplicationRecord
  include Authority::Abilities
  include PgSearch::Model
  include CachedTitleHstore

  # Из CahedTitleHstore приходит свой :ordered, но нам важнее этот
  class << self; remove_method :ordered; end

  include Sortable
  include Archivable
  include MoyskladEntity
  include CategoryCounters
  include CategoryVkontakte
  include CurrentVendor
  include Slugable
  include SeoFields
  include ProductsPerPage
  include CustomTitleHstore
  include RoutesConcern
  include NextResourceConcern
  include CategoryStatus

  has_ancestry orphan_strategy: :rootify

  ranks :position, with_same: %i[ancestry vendor_id], scope: :alive

  mount_uploader :image, ImageUploader

  self.authorizer_name = 'CategoryAuthorizer'

  scope :by_vendor, ->(vendor) { where vendor_id: vendor.id }

  scope :has_any_published_goods, -> { where 'deep_published_products_count>0' }
  scope :has_goods, -> { where 'published_products_count>0' }
  scope :not_root, -> { where.not(ancestry: nil) }
  scope :for_auto_menu, ->(vendor) { ordered.has_any_published_goods.alive.where.not(id: [vendor.package_category_id, vendor.welcome_category_id]) }

  pg_search_scope :by_query,
                  against: %i[id cached_title_translations stock_title],
                  using: {
                    tsearch: { dictionary: 'russian' }
                  }

  belongs_to :vendor

  has_many :menu_items, dependent: :destroy
  has_many :category_products, dependent: :destroy
  has_many :products, through: :category_product
  has_many :product_prices, through: :category_products

  has_many :categories_vendor_deliveries, dependent: :destroy
  has_many :vendor_deliveries, through: :categories_vendor_deliveries

  has_many :categories_coupons, dependent: :destroy
  has_many :coupons, through: :categories_coupons

  before_validation :set_vendor
  validates :title, presence: true

  validate :validate_welcome_category, if: :will_save_change_to_archived_at?

  validate :validate_title

  # TODO disable '>' in names because of export to facebook

  alias_attribute :name, :title

  before_create do
    self.local_id = Category.where(vendor_id: vendor_id).maximum(:local_id).to_i + 1
  end

  after_save do
    vendor.update welcome_category_id: nil if archived? && vendor.welcome_category_id == id
  end

  translates :custom_title, :description, :bottom_text, :cached_title

  def self.tree
    roots.ordered.flat_map(&:subtree)
  end

  def full_name_with_translations
    translations = cached_title_with_translations

    if parent.present?
      [parent.cached_title_with_translations, translations].join('/')
    end

    translations
  end

  def self.find_or_create_by_full_name(vendor, name)
    name = name.strip.squish
    parts = name.split('/')
    return nil if parts.blank?

    parent = nil
    parts.each do |part|
      parent = find_or_create_by_name vendor, part, parent
    end

    parent
  end

  def self.find_or_create_by_name(vendor, name, parent = nil)
    raise 'No vendor' if vendor.blank?

    name.strip!
    raise 'No name' if name.blank?

    vendor.reload.with_lock do
      s = parent.present? ? parent.children : all
      s = s.by_name(name).by_vendor(vendor)

      s.first || vendor.categories.create!(custom_title: name, parent: parent)
    end
  end

  alias has_children has_children?

  def alive_ordered_children
    if persisted?
      children.alive.ordered
    else
      Category.none
    end
  end

  def check_ancestry
    VendorDestroy.destroing? vendor_id
  end

  def has_any_published_goods?
    deep_published_products_count.positive?
  end

  def products
    return Product.none if vendor.blank?

    Product.by_category self
  end

  def full_name
    return name unless persisted?

    if parent.present? && vendor.categories.roots.alive.many?
      "#{parent.name}/#{name}"
    else
      name
    end
  end

  def as_option
    [title, id]
  end

  alias to_s full_name

  def default_path(params = {})
    vendor_category_path to_param, params
  end

  def repair_products_positions
    ProductSortableByCategory.arrange_products_in_category id
  end

  def is_root
    is_root?
  end

  def is_welcome
    id == vendor.welcome_category_id
  end

  # Закрыто для изенений
  def linked?
    return @linked unless @linked.nil?

    @linked ||= stock_linked? && vendor.categories_linked?
  end

  def title_slug
    Slugger.slug_postfix full_name
  end

  def alone_archive!
    archive! if children.alive.empty?
  end

  def children_products_view?
    show_children_products? && children.alive.any?
  end

  def min_and_max_product_prices
    min_price = product_prices.minimum(:price_cents)
    max_price = product_prices.maximum(:price_cents)

    return unless min_price && max_price

    [
      Money.new(min_price, vendor.default_currency),
      Money.new(max_price, vendor.default_currency)
    ]
  end

  private

  def validate_welcome_category
    if archived? && vendor.welcome_category_id == id
      errors.add(:vendor, I18n.t('errors.category.no_archive_welcome_category', url: Rails.application.routes.url_helpers.operator_welcome_page_path))
    end
  end

  def set_vendor
    self.vendor_id = parent.vendor_id if parent_id.present?
  end

  def validate_title
    return unless Settings::Features.unique_category_title

    if title.is_a? Hash
      title.each do |key, value|
        validate_locale_title(key, value)
      end
    else
      validate_locale_title(I18n.locale, title)
    end
  end

  def validate_locale_title(locale, title_value)
    return if id == vendor.welcome_category_id

    except_ids = [id, vendor.welcome_category_id].compact

    if vendor.categories.alive.where.not(id: except_ids).find_by('custom_title_translations::hstore @> ?', "\"#{locale}\"=>\"#{title_value}\"")
      errors.add "custom_title_#{locale}", I18n.t('errors.category.already_exists')
    end
  end
end
