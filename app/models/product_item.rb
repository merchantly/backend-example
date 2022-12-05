class ProductItem < ApplicationRecord
  include Authority::Abilities
  include Archivable
  include MoyskladEntity
  include CustomAttributes
  include StockedItem
  include ProductQuantity
  include ElasticCustomAttributes
  include CurrentVendor
  include ProductPackage
  include GoodOrdering
  include CachedTitleHstore
  include CustomTitleHstore
  include LocaleTitle # for pg_search_scope
  include ProductItemEcrNomenclature
  include ProductItemPrices
  include ProductItemSortable

  belongs_to :product, touch: :updated_at
  belongs_to :vendor, touch: :products_updated_at
  counter_culture :product, column_name: :items_count

  has_many :cart_items,  dependent: :restrict_with_exception, as: :good
  has_many :order_items, dependent: :restrict_with_exception, as: :good

  scope :by_article,          ->(article) { where article: article }
  scope :exclude_default,     -> { where is_default: false }
  scope :ordered, -> { ordered_by_product }

  before_validation :set_defaults
  before_save :set_defaults
  after_commit :touch_product, on: %i[create update]

  delegate :has_ordering_goods,
           :amocrm_catalog_element_id,
           :updatable_by?,
           :category,
           :mandatory_index_image,
           :category_id, :category_ids, :category,
           :is_sale, :is_sale?, :sale_percent,
           :selling_by_weight, :selling_by_weight?, :stock_title,
           :is_published, :is_published?,
           :vat, :tax_type,
           :is_digital, :is_digital?,
           :vendor_deliveries,
           :categories,
           :ident,
           :active_digital_keys,
           :has_digital_keys?,
           :default_url,
           :bitrix24_id,
           :public_url,
           :ordering_start_at, :ordering_end_at,
           :update_ordering!,
           to: :product

  translates :custom_title, :cached_title

  alias_attribute :name, :title

  def images
    [image]
  end

  def type
    self.class.name
  end

  def is_new
    false
  end

  def image
    product.mandatory_index_image
  end

  def unique_custom_attributes
    upids = product.unique_properties.map(&:id)
    custom_attributes.select { |a| upids.include? a.property_id }
  end

  def long_title
    my_title = title
    if my_title == product.title
      my_title
    else
      product.title + " (#{title})"
    end
  end

  def sku
    article.presence || (product.sku + "-#{id}")
  end

  delegate :article, to: :product, prefix: true

  def destroy
    archive
    update archived_at: archived_at
  end

  def title
    return custom_title if custom_title.present?
    return default_title if is_default

    if public_custom_attributes.many?
      public_custom_attributes.map(&:readable_value).join(', ')
    elsif public_custom_attributes.any?
      public_custom_attributes.first.to_s
    else
      article.presence || I18n.t('activerecord.attributes.product_item.fallback_title', id: local_id)
    end
  end

  def destroy!
    super
  rescue ActiveRecord::RecordNotDestroyed
    archive!
  end

  def good_custom_attributes
    if is_default
      product.custom_attributes
    else
      custom_attributes
    end
  end

  def alive?
    product.alive? && super
  end

  private

  def default_title
    product.title if product.present?
  end

  def touch_product
    product.items_updated
  end

  def set_defaults
    if product.present?
      self.vendor_id = product.vendor_id
      # self.article = generate_article if self.article.blank?
    end
  end

  # def generate_article
  # self.article = Russian.translit( product.title ) + '-' + (product.items.count+1).to_s
  # end
end
