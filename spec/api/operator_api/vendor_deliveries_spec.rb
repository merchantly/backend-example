require 'rails_helper'

describe OperatorAPI::VendorDeliveries do
  include OperatorRequests

  describe 'POST /vendor_deliveries' do
    it 'create vendor_delivery' do
      params = {
        title: 'Vendor delivery',
        delivery_agent_type: 'OrderDeliveryOther'
      }

      post '/operator/api/v1/vendor_deliveries', params: params

      expect(response.status).to eq 201
    end
  end
end
