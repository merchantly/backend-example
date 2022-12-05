class OpenbillInvoice < OpenbillRecord
  include Archivable
  include MetaSupport

  belongs_to :destination_account, class_name: 'OpenbillAccount'
  belongs_to :service, class_name: 'OpenbillService'

  has_many :transactions, class_name: 'OpenbillTransaction', foreign_key: :invoice_id
  has_many :charges, class_name: 'OpenbillCharge', foreign_key: :invoice_id, dependent: :destroy

  scope :ordered, -> { order 'created_at DESC' }
  scope :not_paid, -> { where 'openbill_invoices.paid_cents < openbill_invoices.amount_cents' }
  scope :paid, -> { where 'openbill_invoices.paid_cents > 0' }
  scope :autochargable, -> { where is_autochargable: true }
  scope :not_paid_autochargable, -> { not_paid.autochargable }
  scope :with_tariff, -> { where "openbill_invoices.meta->'tariff_id' IS NOT NULL" }

  monetize :amount_cents,
           as: :amount,
           with_model_currency: :amount_currency,
           numericality: {
             greater_than: 0
           }

  monetize :paid_cents,
           as: :paid_amount,
           with_model_currency: :amount_currency

  validates :amount, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :title, presence: true
  validates :number, presence: true, uniqueness: true

  validate :check_amount_currency

  before_validation do
    self.date ||= Date.current
  end

  delegate :tariff_id,
           :service,
           :current_paid_to,
           :next_paid_to,
           :months_count,
           to: :meta

  def detailed_description
    buffer = []

    buffer << I18n.t('billing.attach_tariff', tariff: tariff) if tariff.present?

    if current_paid_to.present? && next_paid_to.present?
      buffer << I18n.t('billing.paid_since_to', current_paid_to: current_paid_to, next_paid_to: next_paid_to)
    else
      buffer << I18n.t('billing.paid_since', current_paid_to: current_paid_to) if current_paid_to.present?
      buffer << I18n.t('billing.paid_to', next_paid_to: next_paid_to) if next_paid_to.present?
    end

    buffer << I18n.t('billing.for_service', service: service) if service.present?

    buffer.join("\n")
  end

  def url
    Rails.application.routes.url_helpers.system_invoice_url id || 'test'
  end

  def paid_at
    return transactions.last.created_at if paid?
  end

  def vendor
    return destination_account.reference if destination_account.reference.present? && destination_account.reference.is_a?(Vendor)
  end

  def vendor_id
    vendor.try(:id)
  end

  # Описание для платежек
  def description
    title
  end

  def buyer_name
    return '____' if vendor.blank?

    I18n.t 'billing.buyer_name', legal_name: vendor.invoice_legal_name, vendor_id: vendor.id
  end

  def buyer_inn
    return '___' if vendor.blank?

    vendor.bank_incoming_contractors.first.try(:contractor_inn)
  end

  def tariff
    return Tariff.find_by(id: tariff_id) if tariff_id.present?
  end

  def quantity
    1
  end

  # Цена за штуку
  def price
    amount
  end

  def amount_in_words
    buffer = RuPropisju.amount_in_words(amount.to_f, amount_currency, :ru, always_show_fraction: true)
    buffer[0].mb_chars.capitalize.to_s + buffer[1..]
  end

  def paid?
    payments_amount >= amount
  end

  def has_payments?
    payments_amount > Money.new(0, destination_account.amount_currency)
  end

  # предзаполняем форму оплаты этим методом, что бы инвойсы можно было доплачивать
  def form_amount
    [amount - payments_amount, Money.new(0)].max
  end

  def make_notification?
    return unless enable_notification?
    return true if client_notified_at.blank?

    next_notification_at <= Time.zone.now
  end

  def next_notification_at
    return unless enable_notification?

    if client_notified_at.present?
      client_notified_at + notified_count.days
    else
      Time.zone.now
    end
  end

  def increment_notification!
    touch :client_notified_at
    increment! :notified_count
  end

  def payments_amount
    amount_cents = transactions.sum(:amount_cents)
    Money.new amount_cents, destination_account.amount_currency
  end

  private

  def check_amount_currency
    return if destination_account.blank?

    errors.add(:amount, "Currency of invoice (#{amount_currency} must be equal to destination account currency #{destination_account.amount_currency}") unless amount_currency == destination_account.amount_currency
  end
end
