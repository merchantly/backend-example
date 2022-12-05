module OrderCartItems
  def is_digital_only?
    items.select(&:is_digital?).count == items.count
  end

  def has_any_digital_goods?
    items.find(&:is_digital?)
  end
end
