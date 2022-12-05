require 'rails_helper'

RSpec.describe System::InvoicesController, type: :controller do
  render_views

  let(:vendor) { create :vendor }
  let(:tariff) { create :tariff }
  let(:openbill_invoice) { create :openbill_invoice, destination_account: vendor.common_billing_account }

  describe 'GET pdf invoice' do
    it 'returns http success' do
      get :show, params: { id: openbill_invoice.id, format: :pdf }
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show, params: { id: openbill_invoice.id }
      expect(response.status).to eq 200
    end
  end
end
