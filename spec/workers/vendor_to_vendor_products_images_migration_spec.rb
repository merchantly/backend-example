require 'rails_helper'

describe VendorToVendorProductsImagesMigrationWorker, :vcr do
  subject { described_class.new }

  let(:vendor) { create :vendor }
  let(:dest_vendor) { create :vendor }

  describe '#perform' do
    context 'dest_vendor has no images' do
      let!(:product) { create :product, :images, vendor: vendor, ms_uuid: '123' }
      let!(:product2) { create :product, vendor: dest_vendor, ms_uuid: '123' }

      before { subject.perform(vendor.id, dest_vendor.id) }

      it 'creates images' do
        expect(product2.reload.product_images.first.digest).to eq product.product_images.first.digest
      end
    end
  end
end
