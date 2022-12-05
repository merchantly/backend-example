class MenuItemDictionaryEntity < MenuItem
  validates :dictionary_entity, presence: true

  def self.model_name
    superclass.model_name
  end

  def entity_title
    dictionary_entity.try :name
  end

  def entity
    dictionary_entity
  end

  def url
    dictionary_entity.try :public_path
  end

  def products_count
    if vendor.show_out_of_stock_products
      dictionary_entity.try :published_products_count
    else
      dictionary_entity.try :published_and_ordering_products_count
    end
  end

  def children
    []
  end
end
