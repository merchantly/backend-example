require 'rails_helper'

RSpec.describe Operator::CouponsController, type: :controller do
  include OperatorControllerSupport

  let(:coupon) { build :coupon_single, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    let(:coupon) { create :coupon_single, vendor: vendor }

    it 'returns http success' do
      get :edit, params: { id: coupon.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.coupons).to receive :create!
      post :create, params: { coupon: coupon.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    let(:coupon) { create :coupon_single, vendor: vendor, used_count: 0 }

    it 'redirects' do
      expect_any_instance_of(Coupon).to receive :update!
      patch :update, params: { id: coupon.id, coupon: coupon.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'GET new_import' do
    it 'redirects' do
      get :new_import
      expect(response.status).to eq 200
    end
  end

  describe 'POST import' do
    it 'returns http success' do
      expect_any_instance_of(CouponsImportService).to receive :perform
      post :import, params: { coupon: { asdf: 123 } }
      expect(response.status).to eq 302
    end
  end
end
