require 'rails_helper'

describe ProductsCategoriesUpdateBatchWorker do
  subject { described_class.new }

  let!(:vendor) { create :vendor }
  let!(:remove_category) { create :category, vendor: vendor }
  let!(:add_category)    { create :category, vendor: vendor }
  let!(:product) { create :product, vendor: vendor, category_ids: [remove_category.id] }
  let!(:product2) { create :product, vendor: vendor, category_ids: [add_category.id] }

  before do
    vendor.update default_product_position: :first
  end

  it { expect(add_category.products_count).to eq 0 }

  describe '#perform' do
    it 'must change categories' do
      subject.perform(vendor.id, [product.id], [add_category.id], [remove_category.id])
      expect(product.reload.category_ids).to include add_category.id
      expect(product.reload.category_ids).not_to include remove_category.id
      expect(add_category.reload.products_count).to eq 2
    end
  end
end
