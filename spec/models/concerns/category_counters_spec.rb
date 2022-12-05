require 'rails_helper'

RSpec.describe CategoryCounters, type: :model do
  subject { root_category.reload }

  let(:vendor) { create :vendor }
  let(:root_category) { create :category, vendor: vendor }
  let(:category) { create :category, vendor: vendor, parent: root_category }

  describe 'нет товаров, счетчики пусты' do
    it { expect(subject.products_count).to eq 0 }
    it { expect(subject.published_products_count).to eq 0 }
    it { expect(subject.active_products_count).to eq 0 }
    it { expect(subject.deep_products_count).to eq 0 }
    it { expect(subject.deep_published_products_count).to eq 0 }
    it { expect(subject.deep_active_products_count).to eq 0 }
  end

  context do
    let(:category)         { create :category, vendor: vendor, parent: root_category }
    let(:sibling_category) { create :category, vendor: vendor, parent: root_category }
    let(:product)          { create :product, vendor: vendor, category_ids: [category.id] }
    let(:hidden_product)   { create :product, :not_published, :archived, vendor: vendor, category_ids: [category.id] }

    before do
      product
      hidden_product
    end

    it { expect(category.reload.products_count).to eq 2 }
    it { expect(category.reload.published_products_count).to eq 1 }
    it { expect(category.reload.active_products_count).to eq 1 }
    it { expect(category.reload.deep_products_count).to eq 2 }
    it { expect(category.reload.deep_published_products_count).to eq 1 }
    it { expect(category.reload.deep_active_products_count).to eq 1 }

    it { expect(sibling_category.reload.products_count).to eq 0 }
    it { expect(sibling_category.reload.published_products_count).to eq 0 }
    it { expect(sibling_category.reload.active_products_count).to eq 0 }
    it { expect(sibling_category.reload.deep_products_count).to eq 0 }
    it { expect(sibling_category.reload.deep_published_products_count).to eq 0 }
    it { expect(sibling_category.reload.deep_active_products_count).to eq 0 }

    it { expect(root_category.reload.products_count).to eq 0 }
    it { expect(root_category.reload.published_products_count).to eq 0 }
    it { expect(root_category.reload.active_products_count).to eq 0 }
    it { expect(root_category.reload.deep_products_count).to eq 2 }
    it { expect(root_category.reload.deep_published_products_count).to eq 1 }
    it { expect(root_category.reload.deep_active_products_count).to eq 1 }

    describe 'меняем родительскую категорию' do
      before do
        category.update_attribute :parent, sibling_category
      end

      it { expect(category.reload.products_count).to eq 2 }
      it { expect(category.reload.published_products_count).to eq 1 }
      it { expect(category.reload.active_products_count).to eq 1 }
      it { expect(category.reload.deep_products_count).to eq 2 }
      it { expect(category.reload.deep_published_products_count).to eq 1 }
      it { expect(category.reload.deep_active_products_count).to eq 1 }

      it { expect(sibling_category.reload.products_count).to eq 0 }
      it { expect(sibling_category.reload.published_products_count).to eq 0 }
      it { expect(sibling_category.reload.active_products_count).to eq 0 }
      it { expect(sibling_category.reload.deep_products_count).to eq 2 }
      it { expect(sibling_category.reload.deep_published_products_count).to eq 1 }
      it { expect(sibling_category.reload.deep_active_products_count).to eq 1 }

      it { expect(root_category.reload.products_count).to eq 0 }
      it { expect(root_category.reload.published_products_count).to eq 0 }
      it { expect(root_category.reload.active_products_count).to eq 0 }
      it { expect(root_category.reload.deep_products_count).to eq 2 }
      it { expect(root_category.reload.deep_published_products_count).to eq 1 }
      it { expect(root_category.reload.deep_active_products_count).to eq 1 }
    end
  end
end
