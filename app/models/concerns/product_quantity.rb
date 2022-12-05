module ProductQuantity
  extend ActiveSupport::Concern

  included do
    validates :quantity, numericality: { less_than: ApplicationRecord::MAX_INTEGER, greater_than_or_equal_to: 0 }, allow_blank: true, if: :quantity_validate?
  end

  def quantity
    good_quantity = IntegrationModules.enable?(:ecr) ? nomenclature_quantity : super

    rounded_quantity good_quantity
  end

  def reserve_quantity
    if IntegrationModules.enable?(:ecr)
      return 0 if nomenclature.blank?

      nomenclature.reserve_quantity
    else
      reserve.to_i
    end
  end

  def total_items_quantity
    return quantity if is_a?(ProductItem)

    items.map(&:quantity).compact.inject(:+) || 0.0
  end

  def total_quantity
    if is_a?(ProductItem) || ordering_as_product_only?
      quantity
    else
      total_items_quantity
    end
  end

  def total_quantity=(value)
    self.quantity = value
  end

  def total_reserve_quantity
    return reserve unless IntegrationModules.enable?(:ecr)

    if is_a?(ProductItem) || ordering_as_product_only?
      reserve_quantity
    else
      items.map(&:reserve_quantity).compact.inject(:+) || 0.0
    end
  end

  private

  def quantity_validate?
    return false if is_a?(ProductItem)

    !stock_linked? && !items.exists?
  end

  def nomenclature_quantity
    return 0 if nomenclature.blank?

    nomenclature.free_quantity
  end

  # Вовращаем количество целочисленным,
  # если оно без дроби
  def rounded_quantity(quantity)
    return nil if quantity.nil?

    quantity.to_i == quantity ? quantity.to_i : quantity
  end
end
