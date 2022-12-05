class Product < ApplicationRecord
  include Archivable
  include Authority::Abilities
  include Categorizable
  include ProductOrdering
  include CustomAttributes # ordinary
  include ProductCustomAttributes
  include ElasticCustomAttributes
  include StockedItem
  include PgSearch::Model
  include ProductVkontakte
  include ProductImages
  include SimilarProducts
  include ProductPackage
  include ProductSortableByCategory
  include GoodOrdering
  include ProductDictionaryEntityCounters
  include ProductVideo
  include CurrentVendor
  include SeoFields
  include ProductLabelNew
  include ProductDigital
  include ProductOrderingPeriod

  # ProductOrdinary
  include ProductPartOfUnion
  include MoyskladEntity
  include ProductItemsDependency
  include ProductQuantity
  include ProductWeight

  include CustomTitleHstore
  include CustomDescriptionHstore
  include CachedTitleHstore
  include CachedDescriptionHstore

  # for pg_search_scope
  include LocaleTitle
  include LocaleDescription

  include Slugable
  include TimeScopes

  include MaxProductsFull

  include RoutesConcern
  include ProductGoods
  include ProductTags
  include ProductPrices

  include ProductEcrNomenclature

  include ProductStatus

  self.authorizer_name = 'ProductAuthorizer'

  belongs_to :vendor, touch: :products_updated_at

  has_many :text_blocks, dependent: :destroy, inverse_of: :product

  has_many :order_items,
           dependent: :restrict_with_exception,
           as: :good

  has_many :category_products, -> { order :row_order }, dependent: :destroy
  has_many :categories, through: :category_products

  # Категория для хлебных крошек
  belongs_to :main_category, class_name: 'Category'

  has_many :cart_items, as: :good
  has_many :wishlist_items, dependent: :destroy

  has_many :product_images, dependent: :destroy
  has_many :products, dependent: :nullify, foreign_key: :product_union_id, inverse_of: :product_union

  has_many :items,
           dependent: :delete_all,
           class_name: 'ProductItem',
           inverse_of: :product

  has_many :digital_keys
  has_one :digital_keys_import

  has_many :products_vendor_deliveries, dependent: :destroy
  has_many :vendor_deliveries, through: :products_vendor_deliveries

  has_many :coupons_products, dependent: :destroy
  has_many :coupons, through: :coupon_products

  counter_culture :vendor

  # Товары с которыми работаем (все кроме частей)
  scope :common,           -> { where product_union_id: nil }
  scope :unions,           -> { where type: 'ProductUnion' }
  scope :as_product,       -> { where type: 'Product' }
  scope :parts,            -> { where.not(product_union_id: nil) }
  scope :active,           -> { alive }

  scope :by_article,       ->(article) { where article: article }
  scope :for_publishing,   -> { published.ordered }
  scope :by_ilike,         ->(query) { where 'title ILIKE ?', query }
  scope :orderable,        -> { where has_ordering_goods: true }
  scope :not_orderable,    -> { where has_ordering_goods: false }

  scope :rational_ordered, -> { order(cached_is_run_out: :asc, is_sale: :desc, cached_has_images: :desc) }

  pg_search_scope :by_query,
                  against: %i[
                    id article
                    locale_title_ru locale_title_en locale_title_ar_SA
                    locale_description_ru locale_description_en locale_description_ar_SA
                  ],
                  associated_against: {
                    items: %i[locale_title_ru locale_title_en locale_title_ar_SA]
                  },
                  using: {
                    tsearch: { dictionary: 'russian' }
                  }

  strip_attributes

  validates :title, presence: true

  validates :h1, length: { maximum: 255 }

  before_validation :set_default_category, if: proc { category.blank? } if IntegrationModules.enable?(:ecr)
  before_validation :remove_default_category, if: :will_change_categories? if IntegrationModules.enable?(:ecr)

  accepts_nested_attributes_for :category_products
  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :text_blocks,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes.all? { |key, value| key == '_destroy' || value.blank? || key == 'format' } }

  alias_attribute :name, :title

  PRODUCT_TYPES = %i[union part separate].freeze

  delegate :min_price, :max_price, :has_different_prices?, to: :prices

  delegate :vat, :barcode, to: :ecr_nomenclature, allow_nil: true

  translates :custom_title, :custom_description, :cached_title, :cached_description

  belongs_to :coupon_image

  def sku
    article.presence || "product-#{id}"
  end

  def has_any_price?
    if has_different_prices?
      prices.has_any_price?
    else
      min_price.present?
    end
  end

  def product_type
    if is_union
      :union
    elsif is_part_of_union
      :part
    else
      :separate
    end
  end

  def is_union?
    products.any? rescue false
  end

  def prices
    Prices.new goods: goods
  end

  def long_title
    title
  end

  def published?
    is_published
  end

  def ident
    code || article || local_id
  end

  def product_article
    article.presence || ident
  end

  def local_id
    "##{id}"
  end

  def has_any_sales
    is_sale
  end

  def to_s
    inspect
  end

  def is_ordered?
    order_items.any?
  end

  def remove_from_index?
    archived?
  end

  def default_path(params = {})
    vendor_product_path to_param, params
  end

  def default_url
    vendor_product_url to_param, host: vendor.home_url
  end

  def update_cached_public_url
    update_column :cached_public_url, public_url
  end

  def main
    if is_part_of_union?
      product_union
    else
      self
    end
  end

  def tax_type
    custom_tax_type.presence || vendor.tax_type
  end

  def alive_category_ids
    categories.alive.pluck(:id)
  end

  def set_default_category
    default_category = current_vendor.welcome_category

    unless default_category.valid?
      Bugsnag.notify "Welcome category is invalid: #{default_category.id}"
      return
    end

    self.category = default_category
  end

  def remove_default_category
    default_category = current_vendor.welcome_category

    if (category_ids & [default_category.id]).present? && (category_ids - [default_category.id]).present?
      self.category_ids = category_ids.without(default_category.id)
    end
  end

  private

  def update_product_fields
    return if archived_at.present?

    ProductSearchFieldsUpdateWorker.perform_async(id)
  end

  def will_change_categories?
     category_products.select(&:saved_changes?).present?
  end
end
