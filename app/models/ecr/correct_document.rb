class Ecr::CorrectDocument < Ecr::Document
  belongs_to :cashier

  after_create :create_transactions!

  def drawer
    cashier.drawers.by_any_document_id(id).take
  end

  def details
    'Correct amount for draw'
  end

  def credit
    amount_positive? ? amount : Money.zero
  end

  def debit
    amount_positive? ? Money.zero : amount.abs
  end

  private

  def create_transactions!
    if amount_positive?
      from_account = vendor.correct_account
      to_account = cashier.account
    else
      from_account = cashier.account
      to_account = vendor.correct_account
    end

    transactions.create!(
      from_account: from_account,
      to_account: to_account,
      key: "document-correct-#{id}",
      amount: amount.abs,
      details: 'Correct', # TODO
      date: Time.zone.today,
      meta: {
        expense_account_id: vendor.correct_account.id,
        account_id: cashier.account.id,
        amount_cents: amount.cents,
        amount_currenct: amount.currency
      }
    )
  end

  def amount_positive?
    amount > Money.zero
  end
end
