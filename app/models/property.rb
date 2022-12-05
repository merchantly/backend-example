require 'securerandom'

class Property < ApplicationRecord
  self.table_name = :vendor_properties

  include MoyskladEntity
  include Archivable
  include Authority::Abilities
  include GenerateKey
  include PropertyConversion
  include CachedTitleHstore
  include CustomTitleHstore
  # Из CahedTitleHstore приходит свой :ordered, но нам важнее этот
  class << self; remove_method :ordered; end
  include Sortable

  strip_attributes

  belongs_to :vendor
  belongs_to :dictionary

  scope :used_in_items,        -> { where is_used_in_item: true }
  scope :used_in_products,     -> { where is_used_in_product: true }
  scope :ordered_for_item,     -> { order :position_in_item }
  scope :ordered_for_product,  -> { order :position_in_product }

  scope :for_items,            -> { used_in_items.ordered_for_item }
  scope :for_products,         -> { used_in_products.ordered_for_product }
  scope :for_filter,           -> { alive.where show_in_filter: true }

  # title может быть не уникальным
  # только там мы можем обеспечить возможность импорта
  # переименованных свойств из моегосклада
  # TODO валидировать на уникльность названия в form object
  validates :title, presence: true

  validate do
    errors.add :type, "Unknown type #{type}, must be one of #{PROPERTY_CLASSES}" unless PROPERTY_CLASSES.map(&:name).include?(type)
  end

  after_destroy :delete_from_product_custom_attributes

  translates :custom_title, :cached_title

  # Если сделать nil то падает на String
  # https://app.honeybadger.io/projects/39607/faults/11111641
  def build_attribute_by_value(value = nil)
    attribute_class.new value: value, property: self
  end

  def to_label
    title
  end

  def build_attribute(data = {})
    # Сначала создаем атрибут со свойством
    attribute = attribute_class.new property: self

    # И толкьо затем устаналиваем данные, так как при установке данных
    # может понадобиться свойство
    attribute.assign_data data
    attribute
  end

  def build_attribute_by_string_value(value = nil)
    build_attribute_by_value value
  end

  def self.model_name
    ActiveModel::Name.new Property
  end

  def self.human_name
    I18n.t name, scope: [:properties]
  end

  # имеет смысл ее выводить в форме для установки?
  def editable?
    true
  end

  def details
    if is_a? PropertyDictionary
      "#{self.class.human_name}: #{dictionary}"
    else
      self.class.human_name
    end
  end

  def attribute_class
    AttributeString
  end

  def attr_method
    "attr_#{id}"
  end

  def to_s
    title
  end

  def name
    title
  end

  def key_item_property
    vendor.safe_key_item_property == self
  end

  def key_item_property=(_value)
    vendor.update_attribute :key_item_property, self
  end

  def key
    super.try :to_sym
  end

  def color?
    is_a?(PropertyDictionary) && dictionary.is_a?(DictionaryColor)
  end

  def products_count
    @products_count ||= products.count
  end

  def active_products_count
    @active_products_count ||= products.active.count
  end

  def products
    @products ||= attributed_products.common.active
  end

  def features
    @features ||= attributed_product_items
  end

  def attributed_products
    vendor.products.where('exist(data, ?)', id.to_s)
  end

  def attributed_product_items
    vendor.product_items.where('exist(data, ?)', id.to_s)
  end

  private

  def delete_from_product_custom_attributes
    attributed_products.update_all [%(data = delete("data",?)), id.to_s]
    attributed_product_items.update_all [%(data = delete("data",?)), id.to_s]
  end
end

# Подгружаем все дочерник свойства
# чтобы они отражались в Property.descendants
PROPERTY_CLASSES = [
  PropertyString,
  PropertyText,
  PropertyBoolean,
  PropertyDictionary,
  PropertyDouble,
  PropertyLink,
  PropertyLong,
  PropertyFile,
  PropertyTime
].freeze
