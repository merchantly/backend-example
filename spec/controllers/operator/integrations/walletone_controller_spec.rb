require 'rails_helper'

RSpec.describe Operator::Integrations::WalletoneController, type: :controller do
  include OperatorControllerSupport

  before do
    vendor.vendor_walletone.update_column :state, VendorWalletone::STATE_APPROVED
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { vendor: { theme_attributes: { w1_widget_visible: true } } }
      expect(response.status).to eq 302
      expect(vendor.reload.theme.w1_widget_visible).to eq true
    end
  end
end
