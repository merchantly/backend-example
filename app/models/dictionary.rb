class Dictionary < ApplicationRecord
  include Authority::Abilities
  include MoyskladEntity
  include Archivable
  include CurrentVendor
  include Slugable
  include SeoFields
  include ProductsPerPage
  include GenerateKey
  include CachedTitleHstore
  include CustomTitleHstore
  include RoutesConcern

  mount_uploader :image, ImageUploader

  belongs_to :vendor
  has_many :menu_items, dependent: :destroy
  has_many :entities, dependent: :destroy, class_name: '::DictionaryEntity'
  has_many :properties, dependent: :destroy

  before_validation :generate_key

  validates :title, presence: true

  translates :custom_title, :cached_title

  def self.human_name
    I18n.t name, scope: [:dictionaries]
  end

  def to_s
    title
  end

  def name
    title
  end

  def products
    # ActiveRecord::PreparedStatementInvalid: wrong number of bind variables (1 for 2) in: data \?| ARRAY[?]
    # vendor.products.where('data \?| ARRAY[?]', property_ids)
    properties.map(&:products).flatten.compact
  end

  def color?
    is_a? DictionaryColor
  end

  # Для grouped_method
  #
  def active_entities
    entities.alive
  end

  def default_path(params = {})
    vendor_dictionary_path self, params
  end
end
