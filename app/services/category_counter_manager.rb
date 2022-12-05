class CategoryCounterManager
  include Virtus.model strict: true

  attribute :type, Symbol, required: true, default: :products

  def count(category, *args)
    CategoryItemsCounter.new(
      category: category,
      item_type: type,
      active: args.include?(:active),
      published: args.include?(:published),
      deep: args.include?(:deep)
    )
                        .count
  end
end
