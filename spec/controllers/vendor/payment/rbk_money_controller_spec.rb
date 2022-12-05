require 'rails_helper'

RSpec.describe Vendor::Payment::RbkMoneyController, type: :controller do
  include VendorControllerSupport

  describe 'GET success' do
    it 'returns http success' do
      get :success
      expect(response.status).to eq 200
    end
  end
end
