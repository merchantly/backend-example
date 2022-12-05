class Ecr::WarehouseMovementReceipt < Ecr::WarehouseMovement
  belongs_to :warehouse

  # Refund nomenclature
  belongs_to :warehouse_movement_expense, class_name: 'Ecr::WarehouseMovementExpense'

  monetize :purchase_price_cents,
           as: :purchase_price,
           numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

  after_create do
    update_cell!
    nomenclature.update_purchase_price!(self) if warehouse_movement_expense.blank?
  end

  def total_purchase_price
    purchase_price * quantity
  end

  def warehouse_cell
    @warehouse_cell ||= warehouse.warehouse_cells.find_by(nomenclature: nomenclature)
  end

  private

  def update_cell!
    cell = warehouse_cell || warehouse.warehouse_cells.create!(quantity: 0, nomenclature: nomenclature)
    cell.update quantity: (quantity + cell.quantity)
  end
end
