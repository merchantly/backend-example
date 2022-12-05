require 'rails_helper'

RSpec.describe Operator::TagsController, type: :controller do
  include OperatorControllerSupport

  let!(:tag) { create :tag, vendor: vendor }

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
      get :show, params: { id: tag.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: tag.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.tags).to receive :create!
      post :create, params: { tag: tag.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Tag).to receive :update!
      patch :update, params: { id: tag.id, tag: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(Tag).to receive :destroy!
      delete :destroy, params: { id: tag.id }
      expect(response.status).to eq 302
    end
  end
end
