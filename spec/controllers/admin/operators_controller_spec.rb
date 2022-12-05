require 'rails_helper'

describe Admin::OperatorsController, type: :controller do
  let!(:resource) { create :operator }
  let!(:system_mail_template) { create :system_mail_template }

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
