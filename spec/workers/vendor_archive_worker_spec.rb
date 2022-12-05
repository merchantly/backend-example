require 'rails_helper'

describe VendorArchiveWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor }
  let!(:expired_period) { Date.current - VendorArchive::ARCHIVE_PERIOD - VendorArchive::PAYMENT_AFTER_NOTIFY_PERIOD - 1.day }

  before do
    vendor.update working_to: expired_period, created_at: expired_period, shop_will_archive_notified_at: expired_period
  end

  describe '#perform' do
    it do
      expect_any_instance_of(VendorNotificationService).to receive(:notify_shop_archived)
      expect_any_instance_of(VendorCommand::ArchiveCommand).to receive(:call)
      expect { subject.perform(vendor.id) }.not_to raise_error
    end
  end
end
