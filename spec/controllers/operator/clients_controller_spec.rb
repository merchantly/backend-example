require 'rails_helper'

RSpec.describe Operator::ClientsController, type: :controller do
  include OperatorControllerSupport

  let(:client) { create :client, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: client.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: client.id }
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(Client).to receive :update!
      patch :update, params: { id: client.id, client: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'POST export' do
    let(:clients) { Client.where(id: client.id) }

    it 'returns http success' do
      allow_any_instance_of(Vendor).to receive(:clients).and_return clients
      post :export
      expect(response.status).to eq 200
    end
  end
end
