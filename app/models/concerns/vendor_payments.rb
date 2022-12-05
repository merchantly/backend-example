module VendorPayments
  extend ActiveSupport::Concern

  included do
    has_many :vendor_payments, dependent: :destroy
    has_many :order_payments, through: :orders
  end

  def rbk_money_secret=(password)
    super password if password.present?
  end

  def default_payment_type
    available_payment_types.first
  end

  def available_payment_types
    vendor_payments.alive.ordered
  end
end
