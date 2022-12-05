class OpenbillTransaction < OpenbillRecord
  include MetaSupport
  include OpenbillTransactionMetrics

  NOTIFIED_MESSAGE = 'Notified'.freeze
  upsert_keys [:key]

  belongs_to :from_account, class_name: 'OpenbillAccount'
  belongs_to :to_account, class_name: 'OpenbillAccount'
  belongs_to :invoice, class_name: 'OpenbillInvoice'

  belongs_to :document, class_name: 'Ecr::Document'

  has_one :reversation_transaction, class_name: 'OpenbillTransaction', foreign_key: :reverse_transaction_id, primary_key: :id

  # Original transaction
  has_one :reverse_transaction, class_name: 'OpenbillTransaction', primary_key: :reverse_transaction_id, foreign_key: :id

  scope :ordered, -> { order 'date desc' }
  scope :by_any_account_id, ->(id) { where('from_account_id = ? or to_account_id = ?', id, id) }
  scope :by_period, lambda { |period|
    scope = all
    scope = scope.where('date >= ?', period.first) if period.first.present?
    scope = scope.where('date <= ?', period.last) if period.last.present?
    scope
  }

  scope :by_month, ->(month) { by_period Range.new(month.beginning_of_month, month.end_of_month) }

  monetize :amount_cents, as: :amount, with_model_currency: :amount_currency

  validates :key, presence: true, uniqueness: true

  delegate :partner_id, to: :meta
  delegate :vendor_id, to: :meta, prefix: :meta

  after_commit :perform_worker, on: :create

  def partner_incoming?
    from_account_id == Billing::PARTNER_ACCOUNT_ID
  end

  def partner
    return if partner_id.blank?

    Partner.find_by(id: partner_id) || raise("Partner #{partner_id} is not found")
  end

  def tariff
    # TODO
  end

  delegate :to_s, to: :id

  def billing_url
    "#{Settings.billing_host}/transactions/#{id}"
  end

  def notify!
    connection.execute "notify #{self.class.table_name}", id
  end

  def locked?
    meta['locked'].to_s == 'true'
  end

  def meta_vendor
    return if meta_vendor_id.blank?

    Vendor.find_by(id: meta_vendor_id) || raise("Vendor #{meta_vendor_id} is not found")
  end

  def vendor_incoming?
    to_account.reference.is_a?(Vendor)
  end

  def vendor_outcoming?
    from_account.reference.is_a?(Vendor)
  end

  def vendor
    return from_account.reference if from_account.reference.is_a?(Vendor)
    return to_account.reference if to_account.reference.is_a?(Vendor)
  end

  private

  def perform_worker
    return if Rails.env.development?

    Billing::TransactionWorker.perform_async id
  end
end
