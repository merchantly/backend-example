class PropertyDictionary < Property
  belongs_to :dictionary

  before_validation do
    if dictionary.present?
      self.title ||= dictionary.title
      self.key ||= dictionary.key
    end
  end

  has_many :entities, through: :dictionary

  def build_attribute_by_value(id = nil)
    attribute_class.new dictionary_entity_id: id, property: self
  end

  def build_attribute_by_string_value(value)
    build_attribute_by_value find_or_create_entity(value).id
  end

  def find_or_create_entity(name)
    dictionary.entities.by_title(name).first || dictionary.entities.create!(custom_title: name)
  end

  def editable?
    entities.alive.any?
  end

  def allow_blank?
    true
  end

  def default_entity
    vendor.dictionary_entities.ordered.first
  end

  def attribute_class
    AttributeDictionary
  end
end
