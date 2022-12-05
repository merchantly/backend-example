class Ecr::RefundDocument < Ecr::Document
  belongs_to :order
  belongs_to :cashier
  belongs_to :sale_document, class_name: 'Ecr::Document'

  after_create :create_transactions!
  after_create :update_order!

  def debit
    amount
  end

  def credit
    Money.zero
  end

  before_validation do
    self.cashier = sale_document.cashier
    self.order = sale_document.order
  end

  private

  def update_order!
    order.update_total_refund_amount!
  end

  def create_transactions!
    transactions.create!(
      from_account: cashier.account,
      to_account: vendor.client_account,
      key: "document-refund-#{sale_document.id}-#{id}",
      amount: amount,
      details: "Refund sale document #{sale_document.id}", # TODO
      date: Time.zone.today,
      meta: { sale_document_id: sale_document.id }
    )
  end
end
