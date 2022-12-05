class Ecr::ReceiptDocument < Ecr::Document
  belongs_to :cashier

  after_create :create_transactions!

  def details
    "Receipt from #{cashier.id}"
  end

  def debit
    Money.zero
  end

  def credit
    amount
  end

  private

  def create_transactions!
    transactions.create!(
      from_account: vendor.receipt_account,
      to_account: cashier.account,
      key: "document-receipt-#{id}",
      amount: amount,
      details: 'Receipt', # TODO
      date: Time.zone.today,
      meta: {
        expense_account_id: vendor.expense_account.id,
        account_id: cashier.account.id,
        amount_cents: amount.cents,
        amount_currenct: amount.currency
      }
    )
  end
end
