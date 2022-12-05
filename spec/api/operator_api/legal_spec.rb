require 'rails_helper'

describe OperatorAPI::Legal do
  include OperatorRequests

  describe 'PUT /legal' do
    let(:params) do
      {
        inn_text: '323456789012343',
        legal_additional_number: 1551,
        legal_street: 'Moscow Street',
        legal_building_number: 1445,
        legal_post_code: '18305',
        legal_city: 'Riyadh',
        legal_province: 'Moscow Province',
        legal_region: 'Moscow Neighborhood',
        legal_country_code: 'SA',
        tin: '1234567899'
      }
    end

    it do
      put '/operator/api/v1/legal', params: params

      expect(response.status).to eq 200
      expect(vendor.reload.inn_text).to eq params[:inn_text]
      expect(vendor.reload.tin).to eq params[:tin]
    end
  end
end
