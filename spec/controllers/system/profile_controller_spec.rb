require 'rails_helper'

RSpec.describe System::ProfileController, type: :controller do
  include OperatorLoggedIn
  render_views

  let(:operator) { create :operator }

  describe 'GET show' do
    it 'return http success' do
      get :show, params: { id: operator.id, subdomain: 'app' }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'return http success' do
      get :edit, params: { id: operator.id, subdomain: 'app' }
      expect(response.status).to eq 200
    end

    it 'with empty email return http success' do
      operator.update_attribute(:email, '')
      get :edit, params: { id: operator.id, subdomain: 'app' }
      expect(response.status).to eq 200
    end
  end

  describe 'POST update' do
    it 'return http success' do
      post :update, params: { id: operator.id, operator: { name: 'asdf', email: 'test@test.com', phone: '+79999999999' }, subdomain: 'app' }
      expect(response.status).to eq 302
    end
  end

  describe 'POST send_email_confirmation' do
    it 'return http success' do
      allow(operator).to receive(:deliver_email_confirmation!)
      post :send_email_confirmation, params: { subdomain: 'app' }
      expect(response.status).to eq 302
    end
  end
end
