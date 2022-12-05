require 'rails_helper'

RSpec.describe 'operator/products/edit', type: :view do
  before do
    view.lookup_context.prefixes << 'operator/products'
    view.lookup_context.prefixes << 'application'

    def view.resource
      true
    end

    def view.active_tab
      :one
    end
  end

  context 'render ordinary product' do
    let(:video_url) { 'https://youtube.com/watch?v=_vQyf6xtc-U' }
    let!(:product) { create :product, video_url: video_url }

    it do
      expect do
        render_described locals: { product: product }
      end.not_to raise_error

      expect(view).to render_template('operator/products/ordinary/_product')
    end
  end

  context 'render union product' do
    let!(:product) { create :product_union }

    it do
      expect do
        render_described locals: { product: product }
      end.not_to raise_error

      expect(view).to render_template('operator/products/union/_product')
    end
  end

  context 'render moysklad product' do
    let!(:vendor) { create :vendor, :moysklad }
    let!(:product) { create :product, :ordering, vendor: vendor }

    before do
      allow(product).to receive(:active_stock_linked?).and_return true
    end

    it do
      expect do
        render_described locals: { product: product }
      end.not_to raise_error

      expect(view).to render_template('operator/products/moysklad/_product')
    end
  end
end
