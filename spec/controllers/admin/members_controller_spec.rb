require 'rails_helper'

describe Admin::MembersController, type: :controller do
  let!(:vendor) { create :vendor }
  let!(:operator) { create :operator }
  let!(:resource) { create :member, operator: operator, vendor: vendor }

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
    it 'returns http success' do
      get :show, params: { id: resource.id }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: resource.id }
      expect(response.status).to eq 200
    end
  end
end
