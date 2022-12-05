module OrderItemWarehouseIssue
  def issue_from_warehouse!
    return if good.blank?

    nomenclature = good.nomenclature

    if nomenclature.warehouse_cells.sum(:reserve_quantity) < quantity
      Bugsnag.notify 'reserved quantity less order item quantity', metaData: { order_id: order.id, item_id: id, quantity: quantity }
      return
    end

    current_quantity = quantity

    nomenclature.warehouse_cells.each do |cell|
      break if current_quantity.zero? || cell.reserve_quantity.zero?

      cell_quantity = current_quantity >= cell.reserve_quantity ? cell.reserve_quantity : current_quantity

      form = Ecr::WarehouseMovementForm::Expense.new(quantity: cell_quantity, vendor: vendor, nomenclature_id: nomenclature.id, warehouse_id: cell.warehouse.id, reserved: true, order_item: self)

      Ecr::WarehouseMovementRegistrar.expense form

      current_quantity -= cell_quantity
    end
  end

  def refund_to_warehouse!
    return if good.blank?

    warehouse_movements.map do |wm|
      form = Ecr::WarehouseMovementForm::Receipt.new(quantity: wm.quantity, vendor: vendor, nomenclature_id: good.nomenclature.id, warehouse_id: wm.warehouse.id, warehouse_movement_expense: wm)

      Ecr::WarehouseMovementRegistrar.receipt form
    end
  end
end
