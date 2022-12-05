require 'rails_helper'

describe OperatorAPI::Orders do
  include OperatorRequests
  let!(:vendor) { create :vendor, :delivery }
  let!(:product) { create :product, :ordering, vendor: vendor }
  let!(:vendor_payment) { create :vendor_payment, :direct, vendor: vendor }

  describe 'POST /orders' do
    let(:order_params) do
      {
        uuid: '32c9d581-b714-455b-a89d-2ef91eb363bb',
        transaction_id: '32c9d581-b714-455b-a89d-2ef91eb363bc',
        tid: '12345678',
        source: 'offline',
        payment_type_id: vendor_payment.id
      }
    end
    let(:client_params) do
      {
        name: 'Name',
        phone: '+79677777777',
        email: 'example@example.com',
      }
    end
    let(:goods_params) { { goods: [{ good_id: product.global_id, count: 1 }].to_json } }
    let(:custom_amounts_params) { { custom_amounts: [{ price_cents: '123', price_currency: 'USD' }].to_json } }

    let(:order_params_with_goods) { order_params.merge(client_params).merge(goods_params) }
    let(:order_params_with_custom_amounts) { order_params.merge(client_params).merge(custom_amounts_params) }

    it 'create order' do
      post '/operator/api/v1/orders', params: order_params_with_goods

      expect(response.status).to eq 201
    end

    it 'create order by custom_amounts' do
      post '/operator/api/v1/orders', params: order_params_with_custom_amounts

      expect(response.status).to eq 201
    end

    it 'create order without client data' do
      post '/operator/api/v1/orders', params: order_params.merge(custom_amounts_params)

      expect(response.status).to eq 201
    end

    it 'product is not published' do
      product.update_column :is_published, false

      post '/operator/api/v1/orders', params: order_params_with_goods

      expect(response.status).to eq 452
      expect(JSON.parse(response.body)['meta']['items']['infos'].keys).to eq [product.global_id]
    end
  end

  describe 'POST /orders with allowance' do
    context 'with products_ids' do
      it do
        params = {
          uuid: '32c9d581-b714-455b-a89d-2ef91eb363bb',
          source: 'offline',
          payment_type_id: vendor_payment.id,
          name: 'Name',
          phone: '+79677777777',
          email: 'example@example.com',
          goods: [{ good_id: product.global_id, count: 1 }].to_json,
          allowance: { discount_type: :percent, discount: 15, product_ids: [product.id] }.to_json
        }

        post '/operator/api/v1/orders', params: params

        expect(response.status).to eq 201
      end
    end

    context 'without products_ids' do
      it 'with products' do
        params = {
          uuid: '32c9d581-b714-455b-a89d-2ef91eb363bb',
          source: 'offline',
          payment_type_id: vendor_payment.id,
          name: 'Name',
          phone: '+79677777777',
          email: 'example@example.com',
          goods: [{ good_id: product.global_id, count: 1 }].to_json,
          allowance: { discount_type: :percent, discount: 15 }.to_json
        }

        post '/operator/api/v1/orders', params: params

        expect(response.status).to eq 201
      end
    end
  end

  describe 'POST /orders with promotions' do
    let!(:promotion) { create :coupon, type: 'Promotion', discount_type: :fixed, discount: 15, vendor: vendor }

    it do
      params = {
        uuid: '32c9d581-b714-455b-a89d-2ef91eb363bb',
        source: 'offline',
        payment_type_id: vendor_payment.id,
        name: 'Name',
        phone: '+79677777777',
        email: 'example@example.com',
        goods: [{ good_id: product.global_id, count: 1, promotion_id: promotion.id }].to_json
      }

      post '/operator/api/v1/orders', params: params

      expect(response.status).to eq 201
    end
  end

  describe 'refund order' do
    let!(:order) { create :order, :items, vendor: vendor }

    it do
      params = {
        items: [{ id: order.items.first.id, quantity: 1, refund_to_warehouse: true }].to_json
      }

      allow(Ecr::OrderRefunder).to receive(:perform).and_return true

      put "/operator/api/v1/orders/#{order.uuid}/refund", params: params

      expect(response.status).to eq 200
    end
  end

  describe 'GET /orders' do
    let!(:payment_key) { VendorPaymentKeys::TERMIAL_PAYMENT_KEY }
    let!(:vendor_payment) { create :vendor_payment, vendor: vendor, payment_key: payment_key }
    let!(:order) { create :order, :items, vendor: vendor, payment_type: vendor_payment }

    it do
      get '/operator/api/v1/orders', params: { payment_key: payment_key }
      expect(response.status).to eq 200
    end
  end
end
