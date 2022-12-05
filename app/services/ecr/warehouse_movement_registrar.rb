class Ecr::WarehouseMovementRegistrar
  def initialize(form)
    @form = form || raise('No form')
  end

  def receipt
    transaction do
      Ecr::WarehouseMovementReceipt.create!(
        warehouse: form.warehouse,
        nomenclature: form.nomenclature,
        quantity: form.quantity,
        purchase_price: form.purchase_price,
        warehouse_movement_expense: form.warehouse_movement_expense
      )
    end
  end

  def expense
    transaction do
      Ecr::WarehouseMovementExpense.create!(
        warehouse: form.warehouse,
        nomenclature: form.nomenclature,
        quantity: form.quantity,
        reserved: form.reserved,
        order_item: form.order_item
      )
    end
  end

  def transfer
    transaction do
      Ecr::WarehouseMovementTransfer.create!(
        from_warehouse: form.from_warehouse,
        to_warehouse: form.to_warehouse,
        nomenclature: form.nomenclature,
        quantity: form.quantity
      )
    end
  end

  class << self
    %i[receipt expense transfer].each do |action|
      define_method action do |form|
        new(form).send action
      end
    end
  end

  private

  attr_reader :form

  def transaction
    Ecr::WarehouseMovement.transaction do
      raise ActiveRecord::RecordInvalid.new(form) unless form.valid?

      yield
    end
  end
end
