require 'rails_helper'

describe Reporters::BalanceSheet do
  subject { described_class.new }

  let!(:vendor) { create :vendor }
  let!(:warehouse) { create :warehouse, vendor: vendor, source: :ecr }
  let!(:nomenclature) { create :nomenclature, vendor: vendor }

  let!(:start_quantity) { 10 }
  let!(:start_price) { 100.to_money }

  let!(:receipt_quantity) { 15 }
  let!(:receipt_price) { 200.to_money }

  let!(:expense_quantity) { 12 }

  let!(:end_quantity) { start_quantity + receipt_quantity - expense_quantity } # 13

  let!(:period_start_at) { Time.zone.parse('1-3-2013 12:12:12') }
  let!(:period_end_at) { Time.zone.parse('7-3-2013 12:12:12') }

  let!(:wm_default_attrs) { { warehouse_id: warehouse.id, nomenclature: nomenclature } }

  let!(:start_wm) { create :receipt_warehouse_movement, wm_default_attrs.merge(quantity: start_quantity, purchase_price: start_price, created_at: (period_start_at - 1.day)) }
  let!(:receipt_wm) { create :receipt_warehouse_movement, wm_default_attrs.merge(quantity: receipt_quantity, purchase_price: receipt_price, created_at: (period_start_at + 1.day)) }
  let!(:expense_wm) { create :expense_warehouse_movement, wm_default_attrs.merge(quantity: expense_quantity, created_at: (period_start_at + 1.day)) }

  it do
    balance_sheet = subject.perform vendor.id, warehouse.id, period_start_at, period_end_at

    nomenclature = balance_sheet.nomenclatures.first

    expect(nomenclature.start_quantity).to eq start_quantity
    expect(nomenclature.receipt_quantity).to eq receipt_quantity
    expect(nomenclature.expense_quantity).to eq expense_quantity
    expect(nomenclature.end_quantity).to eq end_quantity

    expect(nomenclature.start_cost).to eq(start_price * start_quantity) # 100 * 10 = 1000
    expect(nomenclature.end_cost).to eq(160.to_money * end_quantity) # 160 * 13 = 2080
    expect(nomenclature.receipt_cost).to eq(receipt_price * receipt_quantity) # 200 * 15 = 3000
    expect(nomenclature.expense_cost).to eq(160.to_money * expense_quantity) # 160 * 12 = 1920
  end
end
