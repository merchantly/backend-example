require 'rails_helper'

RSpec.describe System::OperatorVendorsController, type: :controller do
  include OperatorLoggedIn
  render_views

  let(:vendor) { create :vendor }
  let!(:operator) { create :operator, :has_vendor }
  let!(:member) { create :member, operator: operator, vendor: vendor }

  describe '#index' do
    it do
      get :index, params: { subdomain: 'app' }
      expect(response.status).to eq(200)
    end
  end
end
