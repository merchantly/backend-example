require 'rails_helper'

RSpec.describe Operator::PropertiesController, type: :controller do
  include OperatorControllerSupport

  let!(:property) { create :property_string, vendor: vendor }

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
      get :show, params: { id: property.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: property.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.properties).to receive :create!
      post :create, params: { property: property.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Property).to receive :update!
      patch :update, params: { id: property.id, property: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(Property).to receive :destroy!
      delete :destroy, params: { id: property.id }
      expect(response.status).to eq 302
    end
  end
end
