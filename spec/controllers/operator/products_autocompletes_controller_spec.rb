require 'rails_helper'

RSpec.describe Operator::ProductsAutocompletesController, :vcr, type: :controller do
  include OperatorControllerSupport

  let!(:product) { create :product, :published, vendor: vendor }
  let(:products_filter) { controller.send(:products_filter) }

  describe 'POST similar' do
    let(:params) { { query: product.name, is_published: true, is_run_out: false, exclude_by_ids: [] } }

    it 'returns http success' do
      post :similar, params: params
      expect(products_filter.is_run_out).to eq false
      expect(products_filter.is_published).to eq true
      expect(products_filter.exclude_by_ids).to be_empty
      expect(response.status).to eq 200
    end
  end

  describe 'POST union' do
    let(:params) { { query: product.name, is_published: true, is_run_out: false, exclude_by_ids: [] } }

    it 'returns http success' do
      post :union, params: params
      expect(products_filter.is_run_out).to eq false
      expect(products_filter.is_published).to eq true
      expect(products_filter.exclude_by_ids).to be_empty
      expect(response.status).to eq 200
    end
  end
end
