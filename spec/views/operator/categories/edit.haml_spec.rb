require 'rails_helper'

RSpec.describe 'operator/categories/edit', type: :view do
  let(:category) { create :category, vendor: vendor }
  let(:new_category) { build :category, vendor: vendor }

  context 'category is persisted' do
    let!(:product) { create :product, category: category, vendor: category.vendor }

    it 'renders form' do
      expect do
        render_described locals: { category: category, products: category.products }
      end.not_to raise_error
      expect(view).to render_template('operator/categories/_form')
    end
  end

  context 'category is not persisted' do
    it 'does not raise errors' do
      expect do
        render_described locals: { category: new_category, parent_category: nil }
      end.not_to raise_error
    end
  end
end
