require 'rails_helper'

RSpec.describe Operator::SlugRedirectsController, type: :controller do
  include OperatorControllerSupport

  let!(:slug_redirect) { create :slug_redirect, vendor: vendor }

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
      get :show, params: { id: slug_redirect.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: slug_redirect.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { slug_redirect: build(:slug_redirect).attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(SlugRedirect).to receive :update!
      patch :update, params: { id: slug_redirect.id, slug_redirect: { is_active: false } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(SlugRedirect).to receive :destroy!
      delete :destroy, params: { id: slug_redirect.id }
      expect(response.status).to eq 302
    end
  end
end
