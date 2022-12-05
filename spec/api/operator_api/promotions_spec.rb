require 'rails_helper'

describe OperatorAPI::Promotions do
  include OperatorRequests

  describe 'GET /promotions' do
    let!(:first_promotion) { create :coupon, type: 'Promotion', is_enabled: true, discount_type: :fixed, discount: 15, vendor: vendor }
    let!(:second_promotion) { create :coupon, type: 'Promotion', discount_type: :percent, discount: 15, vendor: vendor }

    it 'get promotinos' do
      get '/operator/api/v1/promotions'

      expect(response.status).to eq 200
    end
  end
end
