class PaymentToDelivery < ApplicationRecord
  DISCOUNT_TYPES = %w[percent fixed].freeze

  extend Enumerize

  belongs_to :vendor_payment
  belongs_to :vendor_delivery

  enumerize :discount_type, in: DISCOUNT_TYPES, default: 'percent'

  scope :with_discount, -> { where.not(discount: nil) }
  scope :alive, -> { joins(:vendor_delivery, :vendor_payment).where(vendor_deliveries: { archived_at: nil }, vendor_payments: { archived_at: nil }) }

  before_save do
    unless vendor_payment.vendor_id == vendor_delivery.vendor_id
      raise "Vendors are not equal #{vendor_payment_id}, #{vendor_delivery_id}"
    end
  end
end
