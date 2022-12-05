class Ecr::WarehouseMovementTransfer < Ecr::WarehouseMovement
  belongs_to :from_warehouse, class_name: 'Warehouse'
  belongs_to :to_warehouse, class_name: 'Warehouse'

  after_create do
    update_cells!
  end

  def warehouse
    to_warehouse
  end

  def from_cell
    @from_cell ||= from_warehouse.warehouse_cells.find_by(nomenclature: nomenclature)
  end

  def to_cell
    @to_cell ||= to_warehouse.warehouse_cells.create_with(quantity: 0).find_or_create_by!(nomenclature: nomenclature)
  end

  private

  def update_cells!
    from_cell.update! quantity: (from_cell.quantity - quantity)
    to_cell.update! quantity: (to_cell.quantity + quantity)
  end
end
