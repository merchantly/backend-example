require 'rails_helper'

RSpec.describe Operator::DictionariesController, type: :controller do
  include OperatorControllerSupport

  let!(:dictionary) { create :dictionary, vendor: vendor }

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
      get :show, params: { id: dictionary.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: dictionary.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect_any_instance_of(Dictionary).to receive :save!
      post :create, params: { dictionary: dictionary.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Dictionary).to receive :update!
      patch :update, params: { id: dictionary.id, dictionary: { name: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(Dictionary).to receive :destroy!
      delete :destroy, params: { id: dictionary.id }
      expect(response.status).to eq 302
    end
  end
end
