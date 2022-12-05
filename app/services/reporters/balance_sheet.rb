class Reporters::BalanceSheet
  class BalanceSheet
    include Virtus.model

    attribute :nomenclatures, Array

    attribute :total_start_quantity, Float
    attribute :total_receipt_quantity, Float
    attribute :total_expense_quantity, Float
    attribute :total_end_quantity, Float

    attribute :total_start_cost, Money
    attribute :total_end_cost, Money

    attribute :total_receipt_cost, Money
    attribute :total_expense_cost, Money

    attribute :start_at, DateTime
    attribute :end_at, DateTime
    attribute :warehouse, Warehouse
    attribute :vendor, Vendor
  end

  class BalanceSheetNomenclature
    include Virtus.model

    attribute :title, String
    attribute :unit, String

    attribute :start_quantity, Float
    attribute :receipt_quantity, Float
    attribute :expense_quantity, Float

    attribute :start_cost, Money
    attribute :end_cost, Money
    attribute :receipt_cost, Money
    attribute :expense_cost, Money

    def end_quantity
      @end_quantity ||= start_quantity + change_quantity
    end

    def change_quantity
      @change_quantity ||= receipt_quantity - expense_quantity
    end

    def empty?
      end_quantity.zero?
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def perform(vendor_id, warehouse_id = nil, start_at = nil, end_at = nil, show_empty = false)
    balance_sheet.vendor = Vendor.find vendor_id
    balance_sheet.warehouse = balance_sheet.vendor.warehouses.find_by id: warehouse_id
    balance_sheet.start_at = start_at
    balance_sheet.end_at = end_at

    balance_sheet.vendor.nomenclatures.find_each do |nomenclature|
      bsn = buid_bsn(nomenclature)

      next if bsn.empty? && !show_empty

      add_nomenclature_to_balance_sheet(balance_sheet, bsn)
    end

    balance_sheet
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def buid_bsn(nomenclature)
    bsn = BalanceSheetNomenclature.new(
      title: nomenclature.title,
      unit: nomenclature.quantity_unit.title,
      start_quantity: start_quantity(nomenclature),
      receipt_quantity: receipt_quantity(nomenclature, balance_sheet.start_at, balance_sheet.end_at),
      expense_quantity: expense_quantity(nomenclature, balance_sheet.start_at, balance_sheet.end_at)
    )

    sc = start_cost(nomenclature)
    bsn.start_cost = sc[:current_purchase_price] * sc[:current_quantity]

    ec = end_cost(nomenclature, sc[:current_purchase_price], sc[:current_quantity])

    bsn.end_cost = ec[:current_purchase_price] * ec[:current_quantity]
    bsn.receipt_cost = ec[:receipt_cost]
    bsn.expense_cost = ec[:current_purchase_price] * ec[:expense_quantity]

    bsn
  end

  def start_quantity(nomenclature)
    receipt_quantity(nomenclature, nil, balance_sheet.start_at) - expense_quantity(nomenclature, nil, balance_sheet.start_at)
  end

  def receipt_quantity(nomenclature, start_at = nil, end_at = nil)
    nomenclature_quantity(Ecr::WarehouseMovementReceipt, nomenclature, start_at, end_at)
  end

  def expense_quantity(nomenclature, start_at = nil, end_at = nil)
    nomenclature_quantity(Ecr::WarehouseMovementExpense, nomenclature, start_at, end_at)
  end

  def nomenclature_quantity(type, nomenclature, start_at, end_at)
    base_scope(nomenclature, start_at, end_at).by_type(type).sum(:quantity)
  end

  def start_cost(nomenclature)
    nomenclature_cost(nomenclature, nil, balance_sheet.start_at)
  end

  def end_cost(nomenclature, start_purchase_price, start_quantity)
    nomenclature_cost(nomenclature, balance_sheet.start_at, balance_sheet.end_at, start_purchase_price, start_quantity)
  end

  def nomenclature_cost(nomenclature, start_at, end_at, start_purchase_price = Money.zero, start_quantity = 0)
    scope = base_scope(nomenclature, start_at, end_at).by_type([Ecr::WarehouseMovementReceipt, Ecr::WarehouseMovementExpense])

    current_purchase_price = start_purchase_price.clone
    current_quantity = start_quantity.clone

    if scope.empty?
      return { current_purchase_price: current_purchase_price, current_quantity: current_quantity, expense_quantity: 0, receipt_cost: Money.zero }
    end

    receipt_cost = Money.zero
    expense_quantity = 0

    scope.find_each do |wm|
      next if wm.quantity.nil?

      case wm
      when Ecr::WarehouseMovementReceipt
        unless wm.purchase_price.nil?
          current_purchase_price = ((current_purchase_price * current_quantity) + (wm.purchase_price * wm.quantity)) / (current_quantity + wm.quantity)
          receipt_cost += wm.purchase_price * wm.quantity
        end

        current_quantity += wm.quantity
      when Ecr::WarehouseMovementExpense
        current_quantity -= wm.quantity
        expense_quantity += wm.quantity
      else
        raise "Unknown type #{wm.class}"
      end
    end

    {
      current_purchase_price: current_purchase_price,
      current_quantity: current_quantity,
      expense_quantity: expense_quantity,
      receipt_cost: receipt_cost
    }
  end

  def base_scope(nomenclature, start_at, end_at)
    scope = nomenclature.warehouse_movements
    scope = scope.where('created_at > ?', start_at) if start_at.present?
    scope = scope.where('created_at < ?', end_at) if end_at.present?
    scope = scope.where(warehouse_id: balance_sheet.warehouse.id) if balance_sheet.warehouse.present?

    scope
  end

  def balance_sheet
    @balance_sheet ||= build_balance_sheet
  end

  def build_balance_sheet
    BalanceSheet.new(
      nomenclatures: [],
      total_start_quantity: 0,
      total_receipt_quantity: 0,
      total_expense_quantity: 0,
      total_end_quantity: 0,

      total_start_cost: Money.zero,
      total_end_cost: Money.zero,
      total_receipt_cost: Money.zero,
      total_expense_cost: Money.zero
    )
  end

  def add_nomenclature_to_balance_sheet(balance_sheet, nomenclature)
    balance_sheet.nomenclatures << nomenclature
    balance_sheet.total_start_quantity += nomenclature.start_quantity
    balance_sheet.total_receipt_quantity += nomenclature.receipt_quantity
    balance_sheet.total_expense_quantity += nomenclature.expense_quantity
    balance_sheet.total_end_quantity += nomenclature.end_quantity

    balance_sheet.total_start_cost += nomenclature.start_cost
    balance_sheet.total_end_cost += nomenclature.end_cost
    balance_sheet.total_receipt_cost += nomenclature.receipt_cost
  end
end
