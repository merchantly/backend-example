class CategoryItemsCounter
  include Virtus.model

  attribute :category,   Category, required: true
  attribute :item_type,  Symbol, required: true, default: :products
  attribute :active,    Boolean, required: true, default: true
  attribute :published, Boolean, required: true, default: true
  attribute :deep,      Boolean, required: true, default: false

  def count
    scope = items_scope

    scope = deep? ? scope.by_deep_categories(category) : scope.by_category(category)

    scope = scope.published if published?
    scope = scope.active if active?

    scope.count
  end

  private

  def items_scope
    case item_type
    when :products
      vendor.products
    else
      raise "Unknown item_type #{item_type}"
    end
  end

  def vendor
    category.vendor
  end
end
