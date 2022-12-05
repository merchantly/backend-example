require 'rails_helper'

RSpec.describe Operator::SubscriptionEmailsController, type: :controller do
  include OperatorControllerSupport

  let!(:subscription_email) { create :subscription_email, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(SubscriptionEmail).to receive :destroy!
      delete :destroy, params: { id: subscription_email.id }
      expect(response.status).to eq 302
    end
  end
end
