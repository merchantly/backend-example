class MenuItemDictionary < MenuItem
  validates :dictionary, presence: true

  def self.model_name
    superclass.model_name
  end

  def entity_title
    dictionary.try :name
  end

  def entity
    dictionary
  end

  def url
    '#' # TODO для сахарка
    # dictionary.try :path
  end

  def products_count
    0
  end

  def children
    return [] if dictionary.blank?

    dictionary.entities.alive.has_any_published_goods.includes(:slug).ordered.map do |e|
      MenuItemDictionaryEntity.new id: e.id, dictionary_entity: e, vendor: e.vendor
    end
  end
end
