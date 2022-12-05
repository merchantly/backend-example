module DocumentValidation
  extend ActiveSupport::Concern

  included do
    validates :vendor, presence: true
    validates :cashier, presence: true, unless: :is_transfer?

    validates :amount, numericality: { less_than: ApplicationRecord::MAX_INTEGER, greater_than: :amount_greater_than }

    validates :from_cashier, presence: true, if: :is_transfer?
    validates :to_cashier, presence: true, if: :is_transfer?
    validate :equal_cashier?, :enough_balance?, if: :is_transfer?
  end

  private

  def equal_cashier?
    errors.add :to_cashier_id, I18n.t('errors.document.equal_cashier') if from_cashier == to_cashier
  end

  def enough_balance?
    errors.add :amount, I18n.t('errors.document.not_enough_balance') if from_cashier.amount < amount
  end

  def is_sale?
    %(Ecr::SaleDocument, Ecr::DocumentForm::Sale).include? self.class.name
  end

  def is_transfer?
    %(Ecr::TransferDocument, Ecr::DocumentForm::Transfer).include? self.class.name
  end

  def is_correct?
    %(Ecr::CorrectDocument, Ecr::DocumentForm::Correct).include? self.class.name
  end

  def is_expense?
    %(Ecr::ExpenseDocument, Ecr::DocumentForm::Expense).include? self.class.name
  end

  def is_receipt?
    %(Ecr::ReceiptDocument, Ecr::DocumentForm::Receipt).include? self.class.name
  end

  def is_refund?
    %(Ecr::RefundDocument, Ecr::DocumentForm::Refund).include? self.class.name
  end

  def amount_greater_than
    if is_correct?
      -ApplicationRecord::MAX_INTEGER
    else
      0
    end
  end
end
