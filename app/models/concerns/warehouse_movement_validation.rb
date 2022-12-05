module WarehouseMovementValidation
  extend ActiveSupport::Concern

  included do
    validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }
    validates :warehouse, presence: true, if: proc { is_expense? || is_receipt? }

    validate :validate_purchase_price, if: :is_receipt?

    validate :validate_nomenclature, if: :is_expense?
    validate :validate_cell_quantity, if: :is_expense?

    validate :validate_to_warehouse, if: :is_transfer?
    validate :validate_from_warehouse, if: :is_transfer?
    validate :validate_from_cell_quantity, if: :is_transfer?
  end

  private

  def validate_purchase_price
    errors.add :purchase_price, 'The purchase price must be greater than zero' if purchase_price.to_f <= 0 && warehouse_movement_expense.blank?
  end

  def validate_nomenclature
    errors.add :nomenclature_id, 'product not founded to warehouse' if warehouse_cell.blank?
  end

  def validate_cell_quantity
    return if warehouse_cell.blank?

    errors.add :quantity, 'Quantity is more than nomenclature quantity' if warehouse_cell.quantity < quantity
  end

  def validate_to_warehouse
    errors.add :to_warehouse_id, 'From warehouse equal to warehouse' if from_warehouse == to_warehouse
  end

  def validate_from_warehouse
    errors.add :from_warehouse_id, 'Product not founded to warehouse' if from_cell.blank?
  end

  def validate_from_cell_quantity
    errors.add :quantity, 'Quantity is more than from nomenclature quantity' if from_cell.quantity < quantity
  end

  def is_receipt?
    %(Ecr::WarehouseMovementReceipt, Ecr::WarehouseMovementForm::Receipt).include? self.class.name
  end

  def is_expense?
    %(Ecr::WarehouseMovementExpense, Ecr::WarehouseMovementForm::Expense).include? self.class.name
  end

  def is_transfer?
    %(Ecr::WarehouseMovementTransfer, Ecr::WarehouseMovementForm::Transfer).include? self.class.name
  end
end
