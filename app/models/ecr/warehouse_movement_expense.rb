class Ecr::WarehouseMovementExpense < Ecr::WarehouseMovement
  attr_accessor :reserved

  belongs_to :warehouse
  belongs_to :order_item

  after_create do
    update_cell!
  end

  def warehouse_cell
    @warehouse_cell ||= warehouse.warehouse_cells.find_by(nomenclature: nomenclature)
  end

  private

  def update_cell!
    warehouse_cell.update! quantity: (warehouse_cell.quantity - quantity)
    warehouse_cell.update! reserve_quantity: (warehouse_cell.reserve_quantity - quantity) if reserved
  end
end
