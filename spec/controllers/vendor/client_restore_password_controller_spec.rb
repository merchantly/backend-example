require 'rails_helper'

RSpec.describe Vendor::ClientRestorePasswordController, type: :controller do
  include VendorControllerSupport

  let!(:client) { create :client, vendor: vendor }

  describe 'GET show' do
    it 'return http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'send pin code' do
    it 'returns http success' do
      expect_any_instance_of(SmsWorker).to receive(:direct_perform)
      post :update, params: { client_login_form: { login: client.phones.last.phone } }
      expect(response.status).to eq 302
    end
  end

  describe 'send email' do
    it 'returns http success' do
      expect_any_instance_of(ClientResetPasswordMailer).to receive(:send_instructions)
      post :update, params: { client_login_form: { login: client.email.email } }
      expect(response.status).to eq 302
    end
  end
end
