require 'rails_helper'

RSpec.describe Operator::ContentPagesController, type: :controller do
  include OperatorControllerSupport

  let!(:content_page) { create :content_page, title: 'title', vendor: vendor }

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
      get :show, params: { id: content_page.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: content_page.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.content_pages).to receive :create!
      post :create, params: { content_page: content_page.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(ContentPage).to receive :update!
      patch :update, params: { id: content_page.id, content_page: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(ContentPage).to receive :destroy!
      delete :destroy, params: { id: content_page.id }
      expect(response.status).to eq 302
    end
  end
end
