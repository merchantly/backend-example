class VendorPaymentUpdater
  def self.perform(vendor, params, vendor_payment = nil)
    if vendor_payment.present?
      vendor_payment.assign_attributes params
    else
      vendor_payment = vendor.vendor_payments.build params
    end

    vendor_payment.save!

    GeideaCurrenciesChecker.perform_async vendor.id if vendor_payment.geidea_payment?

    vendor_payment
  rescue GeideaPaymentConfig::MerchantIdInvalidError => e
    vendor_payment.errors.add :geidea_payment_merchant_id, e.message

    raise ActiveRecord::RecordInvalid.new(vendor_payment)
  end
end
