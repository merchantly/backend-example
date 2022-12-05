class BankIncoming < ApplicationRecord
  monetize :amount_cents, as: :amount, with_model_currency: :amount_currency

  has_one :contractor, class_name: 'BankIncomingContractor', foreign_key: :contractor_inn, primary_key: :contractor_inn
  has_one :vendor, through: :contractor

  belongs_to :accepted_invoice, class_name: 'OpenbillInvoice'

  enum state: { default: 0, manual_ignored: 1, auto_ignored: 2, manual_accepted: 3, auto_accepted: 4 }

  scope :accepted, -> { where state: %i[manual_accepted auto_accepted] }
  scope :ignored, -> { where state: %i[manual_ignored auto_ignored] }
  scope :not_admin_notified, -> { where admin_notified_at: nil }

  validates :bank_transaction_id, uniqueness: true

  before_create do
    # contractor_name - пустой если это начисление процентов от Tinkoff
    self.state = :auto_ignored if contractor_inn.present? && (have_excludes? || contractor_name.blank?)

    autocreate_contractor if contractor.blank? && state.to_s == 'default'
  end

  # TODO можно еще искать контрагента по названию домена и автоматически создавать контрагента
  after_commit on: :create, if: :invoice do
    BankIncoming.transaction do
      make_transaction
      update_attribute :state, :auto_accepted
    end
  end

  def autocreate_contractor
    invoice = title.split.map { |word| OpenbillInvoice.not_paid.find_by number: word }.compact.first

    create_contractor! vendor: invoice.vendor, contractor_name: contractor_name, contractor_inn: contractor_inn if invoice.present? && invoice.amount == amount
  end

  def to_s
    description
  end

  def description
    [contractor_name, amount, title].join(' ')
  end

  def ignored?
    manual_ignored? || auto_ignored?
  end

  def accepted?
    manual_accepted? || auto_accepted?
  end

  def billing_account
    @billing_account ||= OpenbillAccount.find Billing::IP_PISMENNY_ACCOUNT_ID
  end

  def transaction
    OpenbillTransaction.find_by("meta @> '{\"bank_incoming_id\": #{id}}'")
  end

  def manual_accept!
    t = nil
    BankIncoming.transaction do
      t = make_transaction
      update_attribute :state, :manual_accepted
    end
    t
  end

  def invoice
    @invoice ||= find_vendor_invoice
  end

  def manual_ignore!
    create_exclude
    update! state: :manual_ignored
    BankIncoming.default.where(contractor_inn: contractor_inn).find_each(&:manual_ignore!)
  end

  def create_exclude
    BankIncomingExclude.create contractor_inn: contractor_inn, contractor_name: contractor_name
  end

  def have_excludes?
    BankIncomingExclude.where(contractor_inn: contractor_inn).any?
  end

  private

  def make_transaction
    update_attribute :accepted_invoice, invoice

    if invoice.present? && invoice.destination_account != vendor.common_billing_account
        raise "Не совпадает счет у магазина #{vendor.common_billing_account} со счетом счета #{invoice.destination_account}"
      end

    # Иногда оплата может приниматься без счета
    OpenbillTransaction.create_with(
      from_account: billing_account,
      to_account: invoice.try(:destination_account) || vendor.common_billing_account,
      amount: amount,
      date: bank_transaction_date,
      details: title,
      meta: { bank_transaction_id: bank_transaction_id, bank_incoming_id: id },
      invoice_id: invoice.try(:id)
    ).find_or_create_by(key: bank_transaction_id)
  end

  def find_vendor_invoice
    return nil if vendor.blank?

    find_invoice_by_number || find_invoice_by_amount
  end

  def find_invoice_by_amount
    vendor.invoices.ordered.not_paid.ordered.find_by(amount_cents: amount.cents)
  end

  def find_invoice_by_number
    vendor.invoices.ordered.not_paid.find { |invoice| title.include? invoice.number }
  end
end
