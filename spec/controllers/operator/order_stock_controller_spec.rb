require 'rails_helper'

RSpec.describe Operator::OrderStockController, type: :controller do
  include OperatorControllerSupport

  let!(:order) { create :order, vendor: vendor }

  describe 'POST reserve' do
    it 'returns http success' do
      post :create, params: { order_id: order.id, use_route: 'operator/orders/:order_id/reserve' }
      expect(response.status).to eq 302
    end
  end
end
