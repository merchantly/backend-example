require 'rails_helper'

RSpec.describe Operator::ProductsController, type: :controller do
  include OperatorControllerSupport

  let(:product) { create :product, vendor: vendor }

  describe 'POST reindex' do
    it 'redirects' do
      expect(VendorReindexWorker).to receive :perform_async
      post :reindex
      expect(response.status).to eq 302
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: product.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: product.id }
      expect(response.status).to eq 200
      expect(response).to render_template 'operator/products/edit'
    end

    context 'is_union' do
      let(:product_union) { create :product_union, :products, vendor: vendor }

      it 'renders union' do
        get :edit, params: { id: product_union.id }
        expect(response.status).to eq 200
        expect(response).to render_template 'operator/products/edit'
      end
    end

    context 'stock_linked' do
      before { allow(product).to receive(:active_stock_linked?).and_return true }

      before { product.update_columns ms_uuid: 123 }

      it 'renders union' do
        get :edit, params: { id: product.id }
        expect(response.status).to eq 200
        expect(response).to render_template 'operator/products/edit'
      end
    end
  end

  describe 'PATCH update' do
    let(:price)  { 12_345 }
    let(:params) { { price: price } }

    it 'redirects' do
      patch :update, params: { id: product.id, product: params }
      expect(response.status).to eq 302
    end
  end

  describe 'POST (mocked) create' do
    let(:title)  { 'asdsadasd' }
    let(:price)  { 12_345 }
    let(:params) { { price: price, title: title } }
    let(:product) { vendor.products.build }

    it 'redirects if ok' do
      post :create, params: { product: params }
      expect(response.status).to eq 302
    end

    it 'render new if not ok' do
      expect(controller).to receive(:build_product).and_return product
      expect(product).to receive(:save!).and_raise ActiveRecord::RecordInvalid, product
      post :create, params: { product: params }
      expect(response).to render_template 'operator/products/edit'
    end
  end

  describe 'POST super create' do
    let(:params) do
      {
        'backurl' => '',
        'product' => { 'is_manual_published' => '1',
                       'is_new' => '0',
                       # "image_ids"=>["38595", "38594", ""],
                       'title' => 'were',
                       'price' => '1232',
                       'sale_price' => '',
                       'is_sale' => '0',
                       # "category_ids"=>["4177", "4178"],
                       'description' => '',
                       'article' => '1232',
                       'quantity' => '',
                       # "custom_attributes"=>{"2807"=>{"dictionary_entity_id"=>"12970"}},
                       'text_blocks_attributes' => { '1449121751181' => { 'title' => 'werqwr',
                                                                          'content' => '<p>qwerwe</p>',
                                                                          '_destroy' => 'false',
                                                                          'vendor_id' => vendor.id } },
                       'video_url' => '',
                       'slug_attributes' => { 'id' => '', 'path' => '' },
                       'h1' => '',
                       'meta_title' => '',
                       'meta_description' => '',
                       'meta_keywords' => '',
                       'show_similar_products' => 'auto',
                       'similar_products' => [''] },
        'commit' => 'Сохранить'
      }
    end

    it 'redirects if ok' do
      post :create, params: params
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update #2' do
    let(:p) do
      {
        utf8: '✓',
        _method: 'patch',
        authenticity_token: 'JglhXC6TDQR3maxENIdoO1CmruS7wVau8Sz5P6UJSi8=',
        backurl: '',
        product: {
          is_manual_published: '1',
          is_new: '0',
          image_ids: [
            {},
            {},
            {}
          ],
          title: 'Cycle ring',
          price: '1600.00',
          sale_price: '',
          is_sale: '0',
          category_ids: [
            {}
          ],
          description: '<p>A simple ring for everyone. A perfect circle, which goes with any clothing. Silver 925. Weight 1.4 / 1.5 / 1.6 grams depending on size.</p><p>Кольцо круг. Простое кольцо для каждого. Идеальный круг, носится с любой одеждой. Серебро 925. Вес 1,4 / 1,5 / 1,6 грамм, в зависимости от размера.</p><p>S — 16.3mm | M — 17.1mm | L — 17.9mm</p><p><a href="https://www.facebook.com/wojewellery">facebook</a> / <a href="https://www.instagram.com/w______________o/">instagram</a> / hello@w-o.im</p>',
          article: '',
          quantity: '16.0',
          custom_attributes: {
            '1438093963439': {
              type: 'PropertyString',
              name: 'Size',
              value: 'S'
            },
            '1438093963440': {
              type: 'PropertyString',
              name: 'Size',
              value: 'M'
            },
            '1438093963441': {
              type: 'PropertyString',
              name: 'Size',
              value: 'L'
            }
          },
          video_url: '',
          slug_attributes: {
            id: '',
            path: ''
          },
          h1: '',
          meta_title: '',
          meta_description: '',
          meta_keywords: '',
          show_similar_products: 'auto',
          similar_products: [
            {}
          ]
        },
        commit: 'Сохраняем...',
        action: 'update',
        controller: 'operator/products',
        id: product.id
      }
    end
    let(:params) { p }

    it 'удачно сохранили' do
      patch :update, params: params
      expect(response.status).to eq 302

      expect(product.reload.custom_attributes).to have(3).items
    end
  end

  # describe 'редирект если пытаемся отредактировать продукт в карточке' do
  #   subject { get :edit, id: product.id }

  #   it 'redirects' do
  #     expect(controller).to receive(:product).at_least(:once).and_return product
  #     subject
  #     expect(response.status).to eq 302
  #     expect(response).to redirect_to operator_product_card_path(product.product_card.id)
  #   end
  # end
end
