module VendorDeliveryPayment
  extend ActiveSupport::Concern

  included do
    has_many :payment_to_deliveries
    has_many :vendor_payments, through: :payment_to_deliveries, source: :vendor_payment
  end

  def available_payment?(payment_type)
    return false if payment_type.blank?

    available_payments.include? payment_type
  end

  def available_payments
    vendor_payments.alive.ordered
  end
end
