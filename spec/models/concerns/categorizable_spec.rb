require 'rails_helper'

RSpec.describe Categorizable, type: :model do
  let!(:vendor) { create :vendor }

  describe 'добавили товар прямо в категорию' do
    let(:category) { create :category, vendor: vendor }
    let(:product)  { create :product, :published, vendor: vendor, category_ids: [category.id] }

    before do
      product
    end

    it 'товар должен быть опубликован' do
      expect(product).to be_published
    end

    it { expect(category.reload.products_count).to eq 1 }
    it { expect(category.reload.published_products_count).to eq 1 }
    it { expect(category.reload.active_products_count).to eq 1 }
    it { expect(category.reload.deep_products_count).to eq 1 }
    it { expect(category.reload.deep_published_products_count).to eq 1 }
    it { expect(category.reload.deep_active_products_count).to eq 1 }
  end
end
