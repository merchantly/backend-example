# Отдает все доступные элементы свойства.
# Если это dictionary значит его entity
# В другом случае все возможные значения

class PropertyItems
  include Virtus.model
  attribute :vendor,   Vendor, required: true
  attribute :property, Property, required: true
  attribute :filter,   VendorProductsFilter, required: true

  def available_items(only_ids = nil)
    if property.is_a? PropertyDictionary
      if only_ids.is_a? Array
        dictionary_entities only_ids: only_ids.map(&:to_i)
      else
        dictionary_entities
      end
    else
      entities = common_entities
      return entities if only_ids.blank?

      entities.select do |pe|
        only_ids.include? pe.value
      end
    end
  end

  private

  delegate :category, :dictionary_entity, to: :filter

  def common_entities
    source = category.presence || dictionary_entity.presence || vendor
    available_values(source: source)
      .sort
      .map { |val| PropertyEntity.new(value: val) }
  end

  def dictionary_entities(only_ids: nil, exclude_ids: nil)
    entities = property.dictionary.entities.has_any_published_goods.alive.ordered
    if category.present?
      if only_ids.present?
        ids = only_ids
      else
        ids = available_items_ids source: category
        ids -= exclude_ids if exclude_ids.present?
      end
      entities.where(id: ids)
    elsif dictionary_entity.present?
      if only_ids.present?
        ids = only_ids
      else
        ids = available_items_ids source: dictionary_entity
        ids -= exclude_ids if exclude_ids.present?
      end
      entities.where(id: ids)
    else
      if only_ids.present?
        entities.where(id: only_ids)
      else
        entities
      end
    end
  end

  def available_values(source: nil)
    if property.is_a? PropertyDictionary
      available_items_ids source: source
    else
      available_items_values source: source
    end
  end

  def available_items_values(source: nil)
    products_scope = if source.is_a? Category
                       Product.by_deep_categories(source).common.published
                     else
                       source.products.common.published
                     end

    # учитываем существование ProductUnion
    keys = products_scope.joins(:items).where(product_items: { vendor_id: vendor.id, archived_at: nil }).group("product_items.data -> '#{property.id}'").count.keys +
      products_scope.joins(:products).where(products_products: { vendor_id: vendor.id, archived_at: nil, is_published: true }).group("products_products.data -> '#{property.id}'").count.keys +
      products_scope.group("data -> '#{property.id}'").count.keys

    keys.map(&:presence).compact.uniq
  end

  def available_items_ids(source: nil)
    available_items_values(source: source).map(&:to_i)
  end
end
