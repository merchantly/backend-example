require 'rails_helper'

RSpec.describe Operator::Integrations::PayPalController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    describe 'pay_pal enabled' do
      it 'returns http success' do
        get :show
        expect(response.status).to eq 200
      end
    end
  end

  describe 'PATCH update' do
    let(:email) { 'test@test.com' }

    it 'redirects' do
      patch :update, params: { vendor: { pay_pal_email: email } }
      expect(response.status).to eq 302
      expect(vendor.pay_pal_email).to eq email
    end
  end
end
