require 'rails_helper'

RSpec.describe Operator::Integrations::MoyskladController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  context 'no moysklad' do
    it 'redirects' do
      expect(controller).to receive(:import!)
      post :import
      expect(response.status).to eq 302
    end
  end

  context 'exist moysklad' do
    before do
      vendor.update moysklad_login: 'aaa', moysklad_password: 'bbb'
    end

    it 'redirects' do
      expect(controller).to receive(:import!)
      post :import
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { vendor: { moysklad_login: '123', is_stock_linked: true } }
      expect(response.status).to eq 302
    end
  end
end
