require 'rails_helper'

describe ProductsRestoreBatchWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor }
  let!(:product) { create :product, :archived, vendor: vendor }

  describe '#perform' do
    it do
      expect(product).to be_archived
      subject.perform(vendor.id, [product.id])
      expect(product.reload).not_to be_archived
    end
  end
end
