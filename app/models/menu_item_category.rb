class MenuItemCategory < MenuItem
  validates :category, presence: true

  def self.model_name
    superclass.model_name
  end

  def entity_title
    category.try :name
  end

  def entity
    category
  end

  def url
    category.try :public_path
  end

  def products_count
    if vendor.show_out_of_stock_products
      category.try :deep_published_products_count
    else
      category.try :deep_published_and_ordering_products_count
    end
  end

  def children
    return [] if category.blank?

    category.children.alive.has_any_published_goods.includes(:slug, :vendor).ordered.map do |c|
      MenuItemCategory.new id: c.id, category: c, vendor: c.vendor
    end
  end
end
