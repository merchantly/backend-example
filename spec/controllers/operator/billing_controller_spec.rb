require 'rails_helper'

RSpec.describe Operator::BillingController, type: :controller do
  include OperatorControllerSupport
  let(:vendor) { create :vendor, registration_at: Time.zone.now }
  let(:tariff) { create :tariff }

  before do
    vendor.update tariff: tariff, paid_to: Date.current + 1.week
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end
end
