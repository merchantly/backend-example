class VendorTransactionSMS < VendorTransaction
  def sms_log_entities
    vendor.vendor_sms_log_entities.by_created_at(period_date.beginning_of_month, period_date.end_of_month)
  end
end
