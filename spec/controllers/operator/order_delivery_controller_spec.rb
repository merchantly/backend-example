require 'rails_helper'

RSpec.describe Operator::OrderDeliveryController, type: :controller do
  include OperatorControllerSupport

  let!(:order) { create :order, :delivery_cse, vendor: vendor }

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(OrderDelivery).to receive :update!
      patch :update, params: { order_id: order.id, order: { order_delivery: { date_from: Time.zone.now } } }
      expect(response.status).to eq 302
    end
  end

  describe 'POST start' do
    it 'redirects' do
      post :create, params: { order_id: order.id }
      expect(response.status).to eq 302
    end
  end
end
