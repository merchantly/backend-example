class VirtusQueryString < Virtus::Attribute
  def coerce(value)
    value if value.to_s.size > 2
  end
end
