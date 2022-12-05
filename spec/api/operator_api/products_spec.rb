require 'rails_helper'

describe OperatorAPI::Products do
  include OperatorRequests

  describe 'POST /products' do
    let!(:category) { create :category, vendor: vendor }

    it 'create product' do
      params = {
        title: '3Test',
        article: 1_234_567_890,
        price_cents: 1000,
        category_ids: [category.id]
      }

      post '/operator/api/v1/products', params: params

      expect(response.status).to eq 201
    end
  end

  describe 'get products by barcode' do
    let!(:barcode) { '0000000026733' }
    let!(:nomenclature) { create :nomenclature, vendor: vendor, barcode: barcode }
    let!(:product) { create :product, vendor: vendor, nomenclature: nomenclature }

    before do
      stub_request(:get, /localhost:9200/)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: '{"took":4,"timed_out":false,"_shards":{"total":20,"successful":20,"failed":0},"hits":{"total":0,"max_score":null,"hits":[]}}'
        )
    end

    it do
      get "/operator/api/v1/products?barcode=#{barcode}"

      expect(response.status).to eq 200
    end
  end

  describe 'GET hidden products' do
    let!(:product) { create :product, :not_published, vendor: vendor }

    it do
      get '/operator/api/v1/products', params: { is_hidden: true }

      expect(response.status).to eq 200
    end
  end

  describe 'Update category' do
    let!(:product) { create :product, vendor: vendor, category: categories }
    let!(:category) { create :category, vendor: vendor }

    context 'update when have default category' do
      let!(:categories) { vendor.welcome_category }

      it do
        put "/operator/api/v1/products/#{product.id}", params: { category_ids: [category.id] }

        expect(response.status).to eq 200

        expect(product.reload.category_ids).to eq [category.id]
      end
    end

    # context 'add default category if dont have another' do
    #   let!(:categories) { nil }

    #   it do
    #     product.update_attribute :category, categories

    #     put "/operator/api/v1/products/#{product.id}", params: { title: 'Test title' }

    #     expect(response.status).to eq 200

    #     expect(product.reload.category).to eq vendor.welcome_category
    #   end
    # end

    # context 'dont add default category if update something else and already have category' do
    #   let!(:categories) { create :category, vendor: vendor }

    #   it do
    #     product.update_attribute :category, categories

    #     expect(product.category).to eq categories

    #     put "/operator/api/v1/products/#{product.id}", params: { title: 'Some title' }

    #     expect(response.status).to eq 200

    #     expect(product.reload.category).to eq categories
    #   end
    # end

    # context 'add default category whith another category' do
    #   let!(:categories) { category }

    #   it do
    #     put "/operator/api/v1/products/#{product.id}", params: { category_ids: [category.id, vendor.welcome_category.id] }

    #     expect(response.status).to eq 200

    #     expect(product.reload.category_ids).to eq [category.id]
    #   end
    # end
  end

  describe 'Update barcode' do
    let!(:product) { create :product, :with_nomenclature, vendor: vendor }
    let!(:other_product) { create :product, :with_nomenclature, vendor: vendor }
    let!(:custom_barcode) { '0000000026733' }

    it 'update exist autogenerate barcode' do
      barcode = product.nomenclature.barcode

      put "/operator/api/v1/products/#{other_product.id}", params: { barcode: barcode }

      expect(response.status).to eq 200

      expect(other_product.reload.nomenclature.barcode).to eq barcode
    end

    it 'update exist custom barcode' do
      put "/operator/api/v1/products/#{product.id}", params: { barcode: custom_barcode }

      expect(response.status).to eq 200

      expect(product.reload.nomenclature.barcode).to eq custom_barcode

      put "/operator/api/v1/products/#{other_product.id}", params: { barcode: custom_barcode }

      expect(response.status).to eq 422
    end
  end

  describe 'Get products by category' do
    let!(:category) { create :category, vendor: vendor }
    let!(:product) { create :product, vendor: vendor, category: category }

    it do
      get '/operator/api/v1/products', params: { category_id: category.id, query: product.name }

      expect(response.status).to eq 200
    end
  end

  describe 'Hide and active products' do
    let!(:product) { create :product, vendor: vendor }

    it do
      put "/operator/api/v1/products/#{product.id}/hide"

      expect(response.status).to eq 200

      expect(product.reload.status).to eq(:hidden)

      put "/operator/api/v1/products/#{product.id}/active"

      expect(response.status).to eq 200

      expect(product.reload.status).to eq(:active)
    end
  end
end
