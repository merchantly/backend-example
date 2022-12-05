require 'rails_helper'

RSpec.describe Operator::OrdersController, type: :controller do
  include OperatorControllerSupport

  let!(:order) { create :order, :items, vendor: vendor }
  let!(:product) { create :product, :ordering, vendor: vendor }
  let(:goods)    { { product.id => { good_id: product.global_id, count: product.count } } }

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

  describe 'GET duplicate' do
    it 'returns http success' do
      get :duplicate, params: { id: order.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: order.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: order.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    let(:order_params) { OperatorOrderForm.build_from_order(order).as_json.compact }

    it 'redirects' do
      post :create, params: { operator_order: order_params.merge('goods' => goods) }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { id: order.id, operator_order: { custom_delivery_price: '123' } }
      expect(response.status).to eq 302
    end
  end

  describe 'GET export' do
    it 'returns http success' do
      get :export
      expect(response.status).to eq 200
    end
  end

  describe 'POST notify' do
    it 'returns http success' do
      post :notify, params: { id: order.id }
      expect(response.status).to eq 302
    end
  end
end
