module VendorPaymentDelivery
  extend ActiveSupport::Concern
  included do
    has_many :payment_to_deliveries, dependent: :destroy
    has_many :vendor_deliveries, through: :payment_to_deliveries, source: :vendor_delivery

    accepts_nested_attributes_for :payment_to_deliveries
  end

  def available_deliveries
    return [] unless persisted?

    vendor_deliveries.ordered.alive
  end
end
