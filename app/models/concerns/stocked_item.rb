module StockedItem
  extend ActiveSupport::Concern

  included do
    # orderable?
    # TODO завист от настроек вендора
    scope :stocked,                -> { stock_linked.consignment_linked }
    scope :consignment_linked,     -> { where.not(ms_stockstores: nil) }
    scope :quantity_not_synced,    ->(synced_at) { where "#{arel_table.name}.quantity_synced_at<? or #{arel_table.name}.quantity_synced_at is null", synced_at }

    # Товар можно показывать пользователю
    scope :viewable,               -> { alive }

    # Технически можно купить
    scope :sellable,               lambda { |vendor|
      stocked if vendor.order_stocking_only?
    }

    # Есть нужное пколичество
    scope :quantity, ->(q = 1) { where 'quantity>=?', q }

    # Товар можно заказывать
    # TODO Учитывать vendor.minimal_orderable_quantity
    # scope :ordering,               -> { sellable.viewable.quantity }

    before_save :clean_stock, if: :archived?
  end

  def quantity_unit
    nomenclature.present? ? nomenclature.quantity_unit : default_quantity_unit
  end

  def default_quantity_unit
    selling_by_weight? ? vendor.default_kg_quantity_unit : vendor.default_pcs_quantity_unit
  end

  def max_orderable_quantity
    if quantity_infinity?
      vendor.max_orderable_quantity
    else
      total_quantity
    end
  end

  def orderable_quantity?(q)
    return true if quantity_infinity?

    max_orderable_quantity.to_i >= q
  end

  # Можно показывать
  def viewable?
    alive? && is_published?
  end

  def local_id
    "##{id}"
  end

  # Тоже самое что и quantity, но гаратнированно число
  def count
    quantity.to_i
  end

  def count=(value)
    self.quantity = value
  end

  # Оприходован на складе?
  def consignment_linked?
    ms_stockstores.present?
  end

  def global_id
    to_global_id.to_param
  end

  def clean_stock!
    attrs = { quantity: nil, stock: nil, reserve: nil }
    update attrs
  end

  def quantity_infinity?
    total_quantity.nil?
  end

  def update_quantity!(item_quantity)
    item_quantity = if item_quantity.positive?
                      "+ #{item_quantity.to_i}"
                    else
                      "- #{item_quantity.to_i.abs}"
                    end

    self.class.where(id: id).update_all "quantity = quantity #{item_quantity}"
  end

  private

  def clean_stock
    self.quantity = self.stock = self.reserve = nil
  end
end
