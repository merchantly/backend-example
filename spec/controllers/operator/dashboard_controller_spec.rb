require 'rails_helper'

RSpec.describe Operator::DashboardController, type: :controller do
  include OperatorControllerSupport

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'POST publish_shop' do
    before do
      vendor.update is_published: false
    end

    context 'не оплачен' do
      it do
        post :publish_shop
        expect(response).to redirect_to operator_billing_path
      end
    end

    context 'оплачен' do
      let(:tariff) { create :tariff }

      before do
        vendor.update paid_to: Date.current, working_to: Date.current, tariff: tariff
      end

      it do
        post :publish_shop
        expect(response.status).to eq 302
        expect(vendor.is_published).to be_truthy
      end
    end
  end

  describe 'POST unpublish_shop' do
    it do
      post :unpublish_shop
      expect(response.status).to eq 302
      expect(vendor.is_published).to be_falsey
    end
  end
end
