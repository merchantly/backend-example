# получатели системной рассылки
class SystemMailRecipient < ApplicationRecord
  belongs_to :delivery, class_name: 'SystemMailDelivery', foreign_key: :system_mail_delivery_id, counter_cache: :recipients_count
  belongs_to :system_mail_template
  belongs_to :vendor
  belongs_to :operator
  belongs_to :invoice, class_name: 'OpenbillInvoice'

  scope :sent, -> { where.not(send_at: nil) }
  scope :opened, -> { where.not(open_at: nil) }
  scope :followed, -> { where.not(follow_link_at: nil) }
  scope :paid, -> { joins(:invoice).where 'openbill_invoices.paid_cents > 0' }
  scope :smart_order, -> { order('follow_link_at NULLS LAST, open_at NULLS LAST, send_at NULLS LAST, created_at') }
  scope :unsubscribe_clicked, -> { where.not unsubscribe_clicked_at: nil }

  validates :operator_id, uniqueness: { scope: %i[vendor_id system_mail_delivery_id] }
  validates :email, presence: true, uniqueness: { scope: %i[vendor_id system_mail_delivery_id] }

  before_create do
    self.system_mail_template ||= delivery.system_mail_template
  end

  before_validation do
    self.email ||= operator.try(:email)
  end

  def context
    SystemMailContext.new(
      template: system_mail_template,
      operator: operator,
      vendor: vendor,
      email: email.presence || operator.email,
      invoice: invoice,
      recipient: self
    )
  end

  def deliver!(force: true)
    update_column :send_at, nil if force
    OperatorMailer.system_mail(id).deliver!
  end
end
