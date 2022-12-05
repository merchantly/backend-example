require 'rails_helper'

RSpec.describe SimilarProductsService do
  subject do
    described_class.new(
      product, product.similar_products,
      is_vendor_show_similar: vendor.theme.show_similar_products?,
      is_product_show_similar: !product.show_similar_products.off?,
      auto: product.show_similar_products.auto?,
      count: vendor.theme.similar_products_count
    ).products
  end

  let!(:products) { create_list(:product, 3, :ordering, price: Money.new(12_345), vendor: vendor) }
  let!(:product) { create :product, :ordering, price: Money.new(12_345), vendor: vendor, similar_products_ids: [products.last.id] }

  before { allow_any_instance_of(described_class).to receive(:random_similar_cards).and_return(products.last(2)) }

  shared_examples 'visible' do
    it 'similar products is visible' do
      expect(subject).not_to be_blank
    end
  end

  shared_examples 'hidden' do
    it 'similar products is hidden' do
      expect(subject).to be_blank
    end
  end

  shared_examples 'max_count' do
    it 'similar products count = max_count' do
      expect(subject.count).to eq vendor.theme.category_product_columns
    end
  end

  shared_examples 'selected_count' do
    it 'similar products count = 1' do
      expect(subject.count).to eq 1
    end
  end

  context 'vendor.theme.show_similar_products = on' do
    let(:vendor) { create :vendor, :with_theme }

    before { vendor.theme.update_column :show_similar_products, true }

    context 'product.show_similar_products = auto' do
      before { product.update_column :show_similar_products, 'auto' }

      it_behaves_like 'visible'
      it_behaves_like 'max_count'
    end

    context 'product.show_similar_products = selected_only' do
      before { product.update_column :show_similar_products, 'selected_only' }

      it_behaves_like 'visible'
      it_behaves_like 'selected_count'
    end

    context 'product.show_similar_products = off' do
      before { product.update_column :show_similar_products, 'off' }

      it_behaves_like 'hidden'
    end
  end

  context 'vendor.theme.show_similar_products = false' do
    let(:vendor) { create :vendor, :with_theme }

    before { vendor.theme.update_column :show_similar_products, false }

    context 'product.show_similar_products = auto' do
      before { product.update_column :show_similar_products, 'auto' }

      it_behaves_like 'hidden'
    end

    context 'product.show_similar_products = selected_only' do
      before { product.update_column :show_similar_products, 'selected_only' }

      it_behaves_like 'hidden'
    end

    context 'product.show_similar_products = off' do
      before { product.update_column :show_similar_products, 'off' }

      it_behaves_like 'hidden'
    end
  end
end
