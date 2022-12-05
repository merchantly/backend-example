module OrderAmoCRM
  extend ActiveSupport::Concern

  included do
    after_commit on: :create do
      ::VendorExportOrderAmoCRMWorker.perform_async id if vendor.vendor_amocrm.present? && vendor.vendor_amocrm.is_active?
    end
  end
end
