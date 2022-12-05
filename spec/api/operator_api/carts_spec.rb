require 'rails_helper'

describe OperatorAPI::Carts do
  include OperatorRequests

  describe 'PUT /carts/:id/add_allowance' do
    let!(:cart) { create :cart, :items, vendor: vendor, member: member }
    let(:discount) { 15.5 }
    let(:params) do
      {
        allowance: { discount_type: :fixed, discount: discount }.to_json
      }
    end

    it do
      put "/operator/api/v1/carts/#{cart.id}/add_allowance", params: params

      expect(response.status).to eq 200

      expect(cart.reload.discount_price).to eq discount.to_money
    end
  end
end
