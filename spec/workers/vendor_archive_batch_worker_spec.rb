require 'rails_helper'

describe VendorArchiveBatchWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor, shop_will_archive_notified_at: Date.current - 5.weeks }
  let(:date) { Date.current - 2.months }

  before do
    vendor.update created_at: date, updated_at: date, working_to: date
  end

  describe '#perform' do
    it do
      expect(VendorArchiveWorker).to receive(:perform_async).with(vendor.id)
      expect { subject.perform }.not_to raise_error
    end
  end
end
