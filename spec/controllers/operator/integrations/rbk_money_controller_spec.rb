require 'rails_helper'

RSpec.describe Operator::Integrations::RbkMoneyController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    let(:eshop_id) { '1234' }

    it 'redirects' do
      patch :update, params: { vendor: { rbk_money_eshop_id: eshop_id } }
      expect(response.status).to eq 302
      expect(vendor.rbk_money_eshop_id).to eq eshop_id
    end
  end
end
