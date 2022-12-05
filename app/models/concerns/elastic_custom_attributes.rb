module ElasticCustomAttributes
  # Атрибуты товара и его вариантов
  def elastic_all_custom_attributes
    attrs = elastic_custom_attributes

    goods.each do |i|
      i.elastic_custom_attributes.each_pair do |k, v|
        next if v.blank?

        if attrs.key? k
          attrs[k] = Array attrs[k]
          attrs[k] << v.to_s # чтобы mapping был string
        else
          attrs[k] = v.to_s # чтобы mapping был string
        end
      end
    end

    attrs
  end

  # Атрибуты только элемента
  def elastic_custom_attributes
    return {} if data.blank?

    attrs = {}
    data.each_pair do |k, v|
      next if v.blank?

      attrs[_attr_method(k)] = v.to_s # чтобы mapping был string
    end
    attrs
  end

  private

  def _attr_method(k)
    "attr_#{k}"
  end
end
