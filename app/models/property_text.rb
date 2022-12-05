class PropertyText < Property
  def build_attribute_by_value(value = nil)
    attribute_class.new value: value, property: self
  end

  def attribute_class
    AttributeText
  end
end
