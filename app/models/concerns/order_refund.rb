module OrderRefund
  extend ActiveSupport::Concern

  SCOPES = %i[no_refund partial_refund total_refund].freeze

  included do
    monetize :total_refund_amount_cents, as: :total_refund_amount,
                                         with_model_currency: :total_refund_amount_currency,
                                         allow_nil: false,
                                         numericality: { greater_than_or_equal_to: 0, less_than: Settings.maximal_money }

    scope :total_refund, -> { where.not(total_refund_amount_cents: 0).where('total_refund_amount_cents = total_price_cents') }
    scope :partial_refund, -> { where.not(total_refund_amount_cents: 0).where('total_refund_amount_cents < total_price_cents') }
    scope :no_refund, -> { where(total_refund_amount_cents: 0) }
  end

  def refund_status
    return :no_refund if total_refund_amount.zero?
    return :partial_refund if total_refund_amount < total_price

    :total_refund
  end

  def update_total_refund_amount!
    update total_refund_amount: Money.new(refund_documents.sum(:amount_cents), vendor.currency_iso_code)
  end
end
