require 'rails_helper'

RSpec.describe Operator::VendorPaymentsController, type: :controller do
  include OperatorControllerSupport

  # let!(:vendor)         { create :vendor, :with_w1 }
  let!(:vendor_payment) { create :vendor_payment, :w1, vendor: vendor }

  before do
    vendor.vendor_walletone.update_column :state, VendorWalletone::STATE_APPROVED
  end

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

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: vendor_payment.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { vendor_payment: build(:vendor_payment).attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      patch :update, params: { id: vendor_payment.id, vendor_payment: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end
end
