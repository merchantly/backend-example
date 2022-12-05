require 'rails_helper'

RSpec.describe Vendor::SwaggerController, type: :controller do
  include VendorControllerSupport

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end
end
