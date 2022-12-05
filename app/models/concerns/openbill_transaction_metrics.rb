module OpenbillTransactionMetrics
  extend ActiveSupport::Concern

  included do
    before_commit on: :create do
      @is_first_payment_transaction = !vendor.incoming_openbill_transactions.exists? if vendor.present?
    end

    after_commit :set_metrics, on: :create
  end

  private

  attr_reader :is_first_payment_transaction

  def set_metrics
    $influx.write_point 'merchantly', values: { vendor_first_payment: 0 } if vendor.present? && vendor_incoming? && is_first_payment_transaction
  end
end
