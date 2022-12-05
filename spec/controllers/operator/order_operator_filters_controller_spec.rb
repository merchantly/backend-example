require 'rails_helper'

RSpec.describe Operator::OrderOperatorFiltersController, type: :controller do
  include OperatorControllerSupport

  let!(:order_operator_filter) { create :order_operator_filter, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: order_operator_filter.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: order_operator_filter.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.order_operator_filters).to receive :create!
      post :create, params: { order_operator_filter: order_operator_filter.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(OrderOperatorFilter).to receive :update!
      patch :update, params: { id: order_operator_filter.id, order_operator_filter: { name: 'some', color: '#ffffff' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      delete :destroy, params: { id: order_operator_filter.id }
      expect(response.status).to eq 302
    end
  end
end
