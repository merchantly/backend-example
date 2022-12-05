require 'rails_helper'

RSpec.describe Operator::LookbooksController, type: :controller do
  include OperatorControllerSupport

  let!(:lookbook) { create :lookbook, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'render' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'GET create' do
    it 'creates' do
      post :create, params: { lookbook: { title: 'test' } }
      expect(response.status).to eq 302
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: lookbook.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: lookbook.id }
      expect(response.status).to eq 200
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(Lookbook).to receive :archive!
      delete :destroy, params: { id: lookbook.id }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Lookbook).to receive :update!
      patch :update, params: { id: lookbook.id, lookbook: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
