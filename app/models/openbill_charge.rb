class OpenbillCharge < ApplicationRecord
  belongs_to :invoice, class_name: 'OpenbillInvoice'
  belongs_to :payment_account

  has_one :vendor, through: :payment_account

  scope :ordered, -> { order id: :desc }

  delegate :amount, to: :invoice
end
