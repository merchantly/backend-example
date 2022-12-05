class Ecr::TransferDocument < Ecr::Document
  attr_accessor :cashier, :debit, :credit

  belongs_to :from_cashier, class_name: 'Ecr::Cashier'
  belongs_to :to_cashier, class_name: 'Ecr::Cashier'

  after_create :create_transactions!

  def for_table(current_cashier)
    first_document = clone
    second_document = clone

    first_document.cashier = from_cashier
    first_document.debit = Money.zero
    first_document.credit = amount

    second_document.cashier = to_cashier
    second_document.debit = amount
    second_document.credit = Money.zero

    return [first_document] if current_cashier == from_cashier
    return [second_document] if current_cashier == to_cashier

    [first_document, second_document]
  end

  private

  def create_transactions!
    transactions.create!(
      from_account: from_cashier.account,
      to_account: to_cashier.account,
      key: "document-move-#{id}",
      amount: amount,
      details: "Move amount from cashier##{from_cashier.id} to cashier##{to_cashier.id}", # TODO
      date: Time.zone.today,
      meta: {
        from_account_id: from_cashier.account.id,
        to_account_id: to_cashier.account.id,
        amount_cents: amount.cents,
        amount_currenct: amount.currency
      }
    )
  end
end
