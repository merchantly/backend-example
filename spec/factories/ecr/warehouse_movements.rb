FactoryBot.define do
  factory :receipt_warehouse_movement, class: '::Ecr::WarehouseMovementReceipt' do
  end

  factory :expense_warehouse_movement, class: '::Ecr::WarehouseMovementExpense' do
  end
end
