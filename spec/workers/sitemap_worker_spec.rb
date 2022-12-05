require 'rails_helper'

describe SitemapWorker do
  subject do
    described_class.new
  end

  let!(:vendor) { create :vendor, :with_ordering_products }

  describe '#perform' do
    it do
      expect(VendorCommand::SitemapGeneratorCommand).to receive(:new).with(vendor).and_call_original
      allow_any_instance_of(VendorCommand::SitemapGeneratorCommand).to receive(:call)

      expect { subject.perform }.not_to raise_error
    end
  end
end
