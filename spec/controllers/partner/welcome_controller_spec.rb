require 'rails_helper'

RSpec.describe Partner::WelcomeController, type: :controller do
  include OperatorLoggedIn
  let!(:operator) { create :operator, :with_partner }
  let!(:vendor) { create :vendor, partner_coupon_code: operator.partner.coupons.first.code }

  before do
    request.host = 'app.test.host'
  end

  describe '#index' do
    it do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
