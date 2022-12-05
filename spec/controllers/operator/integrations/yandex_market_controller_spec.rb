require 'rails_helper'

RSpec.describe Operator::Integrations::YandexMarketController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'GET import' do
    it 'returns http success' do
      post :import
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { products_export: { key: CatalogGenerator::YANDEX_CATALOG_FILE } }
      expect(response.status).to eq 302
    end
  end

  describe 'POST create' do
    it 'returns http success' do
      post :create, params: { yml: { asset: fixture_file_upload('customer_order.xml') } }
      expect(response.status).to eq 302
    end
  end
end
