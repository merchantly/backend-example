require 'rails_helper'

RSpec.describe Vendor::CabinetController, type: :controller do
  include VendorControllerSupport

  let!(:client) { create :client, :with_orders }

  before do
    allow(controller).to receive(:current_client).and_return client
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end
end
