class NomenclatureStockReserver
  include Virtus.model

  attribute :good # Product, ProductItem
  attribute :quantity, Numeric

  def reserve!
    return if quantity.nil?

    raise 'No free quantity' if nomenclature.free_quantity < quantity

    current_quantity = quantity

    warehouse_cell_scope.in_sale.find_each do |cell|
      if current_quantity > cell.free_quantity
        current_quantity -= cell.free_quantity

        cell.update! reserve_quantity: cell.reserve_quantity + cell.free_quantity
      else
        cell.update! reserve_quantity: cell.reserve_quantity + current_quantity
        current_quantity = 0
        break
      end
    end

    raise 'Quantity better zero' if current_quantity.positive?
  end

  def unreserve!
    raise 'No reserve quantity' if nomenclature.reserve_quantity < quantity

    current_quantity = quantity

    warehouse_cell_scope.where.not(reserve_quantity: 0).find_each do |cell|
      if current_quantity > cell.reserve_quantity
        current_quantity -= cell.reserve_quantity

        cell.update! reserve_quantity: 0
      else
        cell.update! reserve_quantity: cell.reserve_quantity - current_quantity
        current_quantity = 0
        break
      end
    end

    raise 'Reserver quantity better zero' if current_quantity.positive?
  end

  private

  def warehouse_cell_scope
    nomenclature.warehouse_cells
  end

  def nomenclature
    @nomenclature ||= good.nomenclature
  end
end
