require 'rails_helper'

class FakesController < Operator::BaseController
end

describe ConstraintFeature do
  include OperatorControllerSupport

  controller(FakesController) do
    def fake_action
      render plain: 'ok'
    end

    def check_features
      [:feature_order_state]
    end
  end

  before do
    routes.draw { get 'fake_action' => 'fakes#fake_action' }
  end

  before do
    vendor.update paid_to: Date.current, working_to: Date.current + 2.weeks
  end

  describe 'вендор на старом тарифе' do
    context 'фича выключена' do
      let(:tariff) { create :tariff, feature_order_state: false }

      before do
        vendor.update_attribute :tariff, tariff
      end

      it do
        get :fake_action

        # Пока доступно все и для всех
        # expect(response).to eq redirect_to operator_url
        expect(response.status).to eq 200
      end
    end
  end

  describe 'вендор на старом тарифе' do
    context 'фича включена' do
      let(:tariff) { create :tariff, feature_order_state: true }

      before do
        vendor.update_attribute :tariff, tariff
      end

      it do
        get :fake_action
        expect(response.status).to eq 200
      end
    end
  end
end
