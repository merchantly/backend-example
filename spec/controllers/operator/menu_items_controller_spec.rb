require 'rails_helper'

RSpec.describe Operator::MenuItemsController, type: :controller do
  include OperatorControllerSupport

  let!(:menu_item) { create :menu_item_category, vendor: vendor }

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
      get :edit, params: { id: menu_item.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { menu_item: menu_item.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { id: menu_item.id, menu_item: { custom_title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(MenuItem).to receive :destroy!
      delete :destroy, params: { id: menu_item.id }
      expect(response.status).to eq 302
    end
  end
end
