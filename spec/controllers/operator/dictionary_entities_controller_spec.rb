require 'rails_helper'

RSpec.describe Operator::DictionaryEntitiesController, type: :controller do
  include OperatorControllerSupport

  let!(:dictionary)        { create :dictionary, vendor: vendor }
  let!(:dictionary_entity) { create :dictionary_entity, vendor: vendor, dictionary: dictionary }

  describe 'GET index' do
    it 'returns http success' do
      get :index, params: { dictionary_id: dictionary.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new, params: { dictionary_id: dictionary.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { dictionary_id: dictionary.id, id: dictionary_entity.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { dictionary_id: dictionary.id, dictionary_entity: dictionary_entity.attributes.merge(custom_title_ru: dictionary_entity.custom_title_ru) }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(DictionaryEntity).to receive :update!
      patch :update, params: { dictionary_id: dictionary.id, id: dictionary_entity.id, dictionary_entity: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
