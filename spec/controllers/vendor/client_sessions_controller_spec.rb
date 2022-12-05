require 'rails_helper'

RSpec.describe Vendor::ClientSessionsController, type: :controller do
  include VendorControllerSupport

  let!(:client) { create :client, vendor: vendor, pin_code: 1234 }

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { client_login_form: { login: client.phones.last.phone, password: client.pin_code } }
      expect(response.status).to eq 302
    end
  end

  describe 'GET destroy' do
    it 'redirects' do
      get :destroy
      expect(response.status).to eq 302
    end
  end
end
