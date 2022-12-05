class Ecr::SaleDocument < Ecr::Document
  include DocumentZatca

  belongs_to :order
  belongs_to :cashier

  has_one :refund_document, dependent: :nullify

  after_create :create_transactions!

  def debit
    Money.zero
  end

  def credit
    amount
  end

  def can_reset?
    refund_document.blank?
  end

  private

  def create_transactions!
    transactions.create!(
      from_account: vendor.client_account,
      to_account: cashier.account,
      key: "document-sale-#{id}",
      amount: amount,
      details: "Document sale order №#{order.id}", # TODO
      date: Time.zone.today,
      meta: { order_id: order.id }
    )
  end
end
