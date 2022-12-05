require 'rails_helper'

describe OperatorAPI::Drawers do
  include OperatorRequests

  describe 'open and close drawer' do
    let!(:cashier) { create :cashier, vendor: vendor }
    let!(:opened_at) { '2021-12-20T04:17:001+07:00' }
    let!(:closed_at) { '2021-12-20T04:20:001+07:00' }

    it do
      open_params = {
        opened_at: opened_at,
        open_actual_balance: 123.3,
        cashier_id: cashier.id
      }

      post '/operator/api/v1/drawers', params: open_params

      expect(response.status).to eq 201

      drawer = vendor.drawers.first

      close_params = {
        closed_at: closed_at,
        close_actual_balance: 500
      }

      post "/operator/api/v1/drawers/#{drawer.id}/close", params: close_params

      expect(response.status).to eq 201
    end
  end
end
