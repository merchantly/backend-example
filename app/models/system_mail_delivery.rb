# рассылка шаблонов SystemMailTemplate
class SystemMailDelivery < ApplicationRecord
  extend Enumerize
  include Archivable

  STATE_PREVIEW = :preview
  STATE_DRAFT = :draft
  STATE_PROCESS = :process
  STATE_DONE = :done
  STATES = [STATE_PREVIEW, STATE_DRAFT, STATE_PROCESS, STATE_DONE].freeze

  has_many :recipients, class_name: 'SystemMailRecipient', dependent: :destroy
  belongs_to :system_mail_template, counter_cache: true

  accepts_nested_attributes_for :recipients, allow_destroy: true

  scope :processes, -> { alive.where state: STATE_PROCESS }
  scope :drafts,    -> { alive.where state: STATE_DRAFT }
  scope :dones,     -> { alive.where state: STATE_DONE }
  scope :previews,  -> { where state: STATE_PREVIEW }

  validates :title, :state, presence: true

  enumerize :state, in: STATES, default: STATE_DRAFT

  before_validation do
    self.title ||= system_mail_template.try(:title)
  end

  delegate :template_type,
           :invoice_meta_key,
           :invoice_meta_value,
           to: :system_mail_template

  def utm_campaign
    "delivery:#{id}"
  end

  def add_vendors(vendors)
    vendors.each do |v|
      add_vendor v
    end
  end

  def paid_invoices_count
    @paid_invoices_count ||= recipients.paid.select(:invoice_id).uniq.count
  end

  def paid_amount
    @paid_amount ||= Money.new recipients.paid.sum(:paid_cents) || 0
  end

  def invoices_count
    @invoices_count ||= recipients.select(:invoice_id).uniq.count
  end

  def add_vendor(vendor)
    vendor.operators.system_mail_recipients(template_type).each do |operator|
      recipients.find_or_create_by!(
        vendor: vendor,
        operator: operator,
        invoice: find_invoice(vendor)
      )
    end
  end

  private

  def find_invoice(vendor)
    return if invoice_meta_key.blank?

    invoice = vendor.invoices.find_by("openbill_invoices.meta ->> '#{invoice_meta_key}' = ?", invoice_meta_value)

    raise "Не найдет счет #{invoice_meta_key}=#{invoice_meta_value} для магазина #{vendor.id}" if invoice.blank?

    invoice
  end
end
