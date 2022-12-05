require 'rails_helper'

RSpec.describe Operator::RobotsController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(VendorRobotsResource).to receive :save
      patch :update, params: { vendor: { robots: '123' } }
      expect(response.status).to eq 302
    end
  end

  describe 'GET reset' do
    it 'redirects' do
      get :reset
      expect(response.status).to eq 302
    end
  end
end
