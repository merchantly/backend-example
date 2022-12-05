class DictionaryEntity < ApplicationRecord
  include Authority::Abilities
  include MoyskladEntity
  include Archivable
  include RankedModel
  include CurrentVendor
  include Slugable
  include SeoFields
  include ProductsPerPage
  include CachedTitleHstore
  include CachedDescriptionHstore
  include CustomDescriptionHstore
  include CustomTitleHstore
  include RoutesConcern
  include NextResourceConcern

  mount_uploader :image, ImageUploader

  belongs_to :dictionary, counter_cache: :entities_count
  belongs_to :vendor

  has_many :properties, through: :dictionary
  has_many :menu_items, dependent: :destroy

  ranks :position, with_same: %i[dictionary_id vendor_id], scope: :alive

  scope :has_any_published_goods, -> { where 'published_products_count>0' }
  # Из CahedTitleHstore приходит свой :ordered, но нам важнее этот
  class << self; remove_method :ordered; end
  scope :ordered,                 -> { rank :position }
  scope :ordered_by_value,        -> { order "cached_title_translations::hstore -> '#{HstoreTranslate.locale}'" }

  before_validation :set_name_from_color, if: :color?

  validates :title, presence: true

  after_initialize if: :new_record? do
    self.vendor_id = dictionary.vendor_id if vendor_id.blank? && dictionary.present?
  end

  delegate :color?, to: :dictionary, allow_nil: true

  translates :custom_title, :custom_description, :cached_title, :cached_description

  after_save :update_entities_counter
  after_commit :update_products_counters, on: %i[create update]

  def self.find_or_create_by_title(title)
    by_title(title).first || create(custom_title: title)
  end

  # применяется как значение в фильтре
  def value
    id.to_s
  end

  def image_url
    image.url if image.present?
  end

  def to_s
    title
  end

  def color
    Color::RGB.by_hex color_hex
  rescue ArgumentError
    Color::RGB.by_name 'black'
  end

  def name
    title
  end

  def default_path(params = {})
    vendor_entity_path self, params
  end

  def products
    Product.by_dictionary_entity_id(id)
  end

  def update_products_counters(destroyed_product_id = nil)
    return if vendor.disabled_dictionary_entity_counters?

    base_scope = products.common
    base_scope = base_scope.where.not(id: destroyed_product_id) if destroyed_product_id.present?

    # SELECT COUNT(*) FROM "products" WHERE (1 = ANY(products.dictionary_entity_ids)) AND "products"."product_union_id" IS NULL
    products_count_sql = base_scope.select('COUNT(*)').to_sql

    # SELECT COUNT(*) FROM "products" WHERE (1 = ANY(products.dictionary_entity_ids)) AND "products"."archived_at" IS NULL AND "products"."product_union_id" IS NULL
    active_products_count_sql = base_scope.select('COUNT(*)').to_sql

    # SELECT COUNT(*) FROM "products" WHERE (1 = ANY(products.dictionary_entity_ids)) AND "products"."product_union_id" IS NULL AND "products"."archived_at" IS NULL AND "products"."is_published" = 't'
    published_products_count_sql = base_scope.published.select('COUNT(*)').to_sql

    published_and_ordering_products_count_sql = base_scope.published.good_ordering.select('COUNT(*)').to_sql

    # SELECT COUNT(*) FROM "products" WHERE (1 = ANY(products.dictionary_entity_ids)) AND "products"."product_union_id" IS NULL AND (archived_at is not null)
    archived_products_count_sql = base_scope.archive.select('COUNT(*)').to_sql

    self.class.connection
        .update("UPDATE \"dictionary_entities\" SET \"products_count\" = (#{products_count_sql}),
              \"active_products_count\" = (#{active_products_count_sql}),
              \"published_products_count\" = (#{published_products_count_sql}),
              \"archived_products_count\" = (#{archived_products_count_sql}),
              \"published_and_ordering_products_count\" = (#{published_and_ordering_products_count_sql})
              WHERE \"dictionary_entities\".\"id\" = #{id}")
  end

  private

  def update_entities_counter
    return if vendor.disabled_dictionary_entity_counters?

    dictionary.update_attribute :entities_alive_count, dictionary.entities.alive.count
  end

  def set_name_from_color
    self.title = color.name || color_hex if title.blank?
  end
end
