require 'rails_helper'

describe ProductsTagsUpdateBatchWorker do
  subject { described_class.new }

  let(:vendor) { create :vendor }
  let(:remove_tag) { create :tag, vendor: vendor }
  let(:add_tag)    { create :tag, vendor: vendor }
  let(:product) { create :product, vendor: vendor, tag_ids: [remove_tag.id] }

  describe '#perform' do
    it do
      subject.perform(vendor.id, [product.id], [add_tag.id], [remove_tag.id])
      expect(product.reload.tag_ids).to eq [add_tag.id]
    end
  end
end
