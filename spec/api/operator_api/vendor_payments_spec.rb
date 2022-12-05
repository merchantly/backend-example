require 'rails_helper'

describe OperatorAPI::VendorPayments do
  include OperatorRequests

  describe 'POST /vendor_payments' do
    it 'create vendor_payment' do
      params = {
        title: 'Vendor payment',
        payment_key: 'CASH'
      }

      post '/operator/api/v1/vendor_payments', params: params

      expect(response.status).to eq 201
    end
  end
end
