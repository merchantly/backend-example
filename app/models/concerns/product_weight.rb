module ProductWeight
  extend ActiveSupport::Concern

  included do
    validates :weight_of_price, numericality: { greater_than: 0.0 }, if: :selling_by_weight?
    after_save do
      set_cart_items_weight if selling_by_weight? && saved_change_to_selling_by_weight?
    end
  end

  def selling_by_weight?
    selling_by_weight
  end

  def selling_by_weight
    return super if ecr_nomenclature.blank?

    ecr_nomenclature.quantity_unit == vendor.default_kg_quantity_unit
  end

  private

  # вес будет пустым если покупатель добавил товар в корзину по кол-ву
  # а вендор после этого сделал товар на развес
  def set_cart_items_weight
    cart_items.empty_weight.update_all weight_kg: weight_of_price
  end
end
