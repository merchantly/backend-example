# TODO Преврарить в декоратор
class VendorTransaction
  delegate :id, :created_at, :date, :details, :meta, :key, :to_account, to: :raw_transaction

  delegate :details, to: :opposite_account, prefix: true

  attr_reader :raw_transaction

  MONTH_NAMES = I18n.t :'date.standalone_month_names'

  def initialize(vendor, raw_transaction)
    @vendor = vendor
    @raw_transaction = raw_transaction
  end

  def incoming?
    vendor.openbill_accounts.map(&:id).include? raw_transaction.to_account_id
  end

  def amount
    incoming? ? raw_transaction.amount : -raw_transaction.amount
  end

  def period
    "#{month_name} #{year}"
  rescue StandardError
    '-'
  end

  def period_date
    # Was: Date.parse "1.#{meta['month']}.#{meta['year']}"
    date.presence || created_at.to_date
  end

  def tariff
    @tariff ||= Tariff.find tariff_id
  end

  private

  attr_reader :vendor

  delegate :month, :year, to: :period_date

  def opposite_account
    if incoming?
      raw_transaction.from_account
    else
      raw_transaction.to_account
    end
  end

  def month_name
    MONTH_NAMES[month]
  end
end
