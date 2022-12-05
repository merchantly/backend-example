require 'rails_helper'

RSpec.describe Operator::TranslationsController, type: :controller do
  include OperatorControllerSupport

  let!(:translation) { create :translation, vendor: vendor, key: :not_published }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new, params: { translation: { locale: :ru, key: :not_published } }
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: translation.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: translation.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { translation: translation.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { id: translation.id, translation: { value: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
