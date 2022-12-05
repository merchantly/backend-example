require 'rails_helper'

describe ShopWillArchiveNotifyWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor }
  let(:date) { Date.current - 2.months }

  before do
    vendor.update created_at: date, updated_at: date
  end

  describe '#perform' do
    it do
      expect_any_instance_of(VendorNotificationService).to receive(:notify_shop_will_archive).and_call_original
      expect { subject.perform(vendor.id) }.to(change { vendor.reload.shop_will_archive_notified_at })
    end
  end
end
