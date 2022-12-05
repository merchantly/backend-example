require 'rails_helper'

RSpec.describe Operator::VendorDeliveriesController, type: :controller do
  include OperatorControllerSupport

  let!(:vendor_delivery) { create :vendor_delivery, :cse, vendor: vendor }

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

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: vendor_delivery.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { vendor_delivery: build(:vendor_delivery).attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { id: vendor_delivery.id, vendor_delivery: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
