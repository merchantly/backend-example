require 'rails_helper'

RSpec.describe Operator::Integrations::TorgMailController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { products_export: { key: CatalogGenerator::YANDEX_CATALOG_FILE } }
      expect(response.status).to eq 302
    end
  end
end
