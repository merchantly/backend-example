require 'rails_helper'

RSpec.describe Operator::Integrations::YandexKassaController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    describe 'yandex kassa' do
      it 'returns http success' do
        get :show
        expect(response.status).to eq 200
      end
    end
  end

  describe 'PATCH update' do
    let(:shop_id) { '1234' }

    it 'redirects' do
      patch :update, params: { vendor: { yandex_kassa_shop_id: shop_id } }
      expect(response.status).to eq 302
      expect(vendor.yandex_kassa_shop_id).to eq shop_id
    end
  end
end
