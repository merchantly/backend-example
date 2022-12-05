module VendorDeliveryRestriction
  extend ActiveSupport::Concern

  USE_BEHAVIOR_INCLUDE = 'include'.freeze
  USE_BEHAVIOR_EXCLUDE = 'exclude'.freeze
  USE_BEHAVIORS = [USE_BEHAVIOR_EXCLUDE, USE_BEHAVIOR_INCLUDE].freeze

  included do
    enumerize :use_products_behavior, in: USE_BEHAVIORS, default: USE_BEHAVIOR_EXCLUDE
    enumerize :use_categories_behavior, in: USE_BEHAVIORS, default: USE_BEHAVIOR_EXCLUDE

    has_many :categories_vendor_deliveries, dependent: :destroy
    has_many :categories, through: :categories_vendor_deliveries

    has_many :products_vendor_deliveries, dependent: :destroy
    has_many :products, through: :products_vendor_deliveries
  end

  def has_restrictions?
    category_ids.present? || product_ids.present?
  end

  def restriction_satisfy?(products)
    return true unless has_restrictions?

    item_product_ids = products.map(&:id)
    item_category_ids = products.map(&:category_ids)

    satisfy_product_behavior?(item_product_ids) && satisfy_category_behavior?(item_category_ids)
  end

  def product_ids
    return [] if super.blank?

    product_union_ids = Product.where(product_union_id: super).pluck(:id)

    (super + product_union_ids).uniq
  end

  private

  def satisfy_product_behavior?(item_product_ids)
    return true if product_ids.blank?

    case use_products_behavior
    when USE_BEHAVIOR_INCLUDE
      # Отсутсвуют ли товары которых нет в списке разрешенных?
      (item_product_ids - product_ids).empty?
    when USE_BEHAVIOR_EXCLUDE
      # Отсутствуют ли товары которые есть в списке запрещенных?
      (item_product_ids & product_ids).empty?
    else
      raise "Unknown #{use_products_behavior}"
    end
  end

  def satisfy_category_behavior?(item_category_ids)
    return true if category_ids.blank?

    case use_categories_behavior
    when USE_BEHAVIOR_INCLUDE
      # Если в кажлом товаре есть одна категория из списка разрешенных категории
      item_category_ids.map { |ids| (category_ids & ids).present? }.reduce(:&)
    when USE_BEHAVIOR_EXCLUDE
      # Если у каждого товара отсутсвует категория из списка запрещенных категории
      item_category_ids.map { |ids| (category_ids & ids).blank? }.reduce(:&)
    else
      raise "Unknown #{use_categories_behavior}"
    end
  end
end
