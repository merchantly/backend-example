class Ecr::CashierAmountCalculator
  include Virtus.model

  attribute :cashier, Ecr::Cashier

  delegate :vendor, to: :cashier

  def total_amount(start_at = nil, finish_at = nil)
    sale_amount(start_at, finish_at) +
      receipt_amount(start_at, finish_at) -
      refund_amount(start_at, finish_at) -
      expense_amount(start_at, finish_at) +
      to_transfer_amount(start_at, finish_at) -
      from_transfer_amount(start_at, finish_at) +
      correct_amount(start_at, finish_at)
  end

  def sale_amount(start_at = nil, finish_at = nil)
    amount_by_type start_at, finish_at, Ecr::SaleDocument
  end

  def refund_amount(start_at = nil, finish_at = nil)
    amount_by_type start_at, finish_at, Ecr::RefundDocument
  end

  def receipt_amount(start_at = nil, finish_at = nil)
    amount_by_type start_at, finish_at, Ecr::ReceiptDocument
  end

  def expense_amount(start_at = nil, finish_at = nil)
    amount_by_type start_at, finish_at, Ecr::ExpenseDocument
  end

  def to_transfer_amount(start_at = nil, finish_at = nil)
    transfer_amount start_at, finish_at, :to_cashier_id
  end

  def from_transfer_amount(start_at = nil, finish_at = nil)
    transfer_amount start_at, finish_at, :from_cashier_id
  end

  def correct_amount(start_at, finish_at)
    amount_by_type start_at, finish_at, Ecr::CorrectDocument
  end

  private

  def amount_by_type(start_at, finish_at, type)
    Money.new(scope(start_at, finish_at).by_type(type).sum(:amount_cents), vendor.default_currency)
  end

  def transfer_amount(start_at, finish_at, field)
    Money.new(scope(start_at, finish_at).by_type(Ecr::TransferDocument).where(field => cashier.id).sum(:amount_cents), vendor.default_currency)
  end

  def scope(start_at, finish_at)
    current_scope = cashier.all_documents
    current_scope = current_scope.where('created_at >= ?', start_at) if start_at.present?
    current_scope = current_scope.where('created_at <= ?', finish_at) if finish_at.present?
    current_scope
  end
end
