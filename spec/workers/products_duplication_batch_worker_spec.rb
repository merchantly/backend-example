require 'rails_helper'

describe ProductsDuplicationBatchWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor }

  describe '#perform' do
    let(:duplicate) { subject.perform(vendor.id, [product.id], return_duplicate: true) }
    let(:product) { create :product, :images, :property_file, items_count: 1, vendor: vendor, ms_uuid: '123' }

    context 'product ms_uuid' do
      let(:pid) { product.properties.first.id.to_s }

      it 'must return duplicate' do
        expect(duplicate.title).to eq product.title
        expect(duplicate.ms_uuid).to eq nil
        expect(duplicate.code).to eq nil
        expect(duplicate.ms_stockstores).to eq nil
        expect(duplicate.consignment_dump).to eq nil
        expect(duplicate.externalcode).to eq nil
        expect(duplicate.stock_dump).to eq nil
        expect(duplicate.image_ids).to be_present
        expect(duplicate.image_ids).not_to eq product.image_ids
        expect(duplicate.data[pid]).to be_present
        expect(duplicate.data[pid]).to eq product.data[pid]
      end
    end

    context 'product items ms_uuid' do
      let(:product) do
        create(
          :product, :images, :property_file, :items,
          items_count: 1, items_ms_uuid: '456',
          vendor: vendor, ms_uuid: '123'
        )
      end

      it do
        expect { duplicate }.not_to raise_error
      end
    end
  end
end
