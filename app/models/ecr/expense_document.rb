class Ecr::ExpenseDocument < Ecr::Document
  belongs_to :cashier

  after_create :create_transactions!

  def details
    "Expense from #{cashier.id}"
  end

  def debit
    amount
  end

  def credit
    Money.zero
  end

  private

  def create_transactions!
    transactions.create!(
      from_account: cashier.account,
      to_account: vendor.expense_account,
      key: "document-expense-#{id}",
      amount: amount,
      details: 'Expense', # TODO
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
