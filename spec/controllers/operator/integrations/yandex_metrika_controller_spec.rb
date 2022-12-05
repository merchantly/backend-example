require 'rails_helper'

RSpec.describe Operator::Integrations::YandexMetrikaController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    let(:value) { Random.rand(100).to_s }

    it 'redirects' do
      patch :update, params: { vendor: { yandex_metrika_tracking_id: value } }
      expect(response.status).to eq 302
      expect(vendor.reload.yandex_metrika_tracking_id).to eq value
    end
  end
end
