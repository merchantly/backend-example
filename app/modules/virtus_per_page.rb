class VirtusPerPage < Virtus::Attribute
  def coerce(value)
    value = value.to_i
    return if value <= 0

    value < Settings.maximal_per_page ? value : Settings.maximal_per_page
  end
end
