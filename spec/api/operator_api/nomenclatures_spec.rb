require 'rails_helper'

describe OperatorAPI::Nomenclatures do
  include OperatorRequests

  describe 'POST /nomenclatures/:id/*' do
    let!(:nomenclature) { create :nomenclature, vendor: vendor }

    before do
      vendor.send :create_default_warehouse! if vendor.default_warehouse.blank?
    end

    describe 'receipt and expense without warehouse id' do
      let(:receipt_quantity) { 5 }
      let(:expense_quantity) { 3 }
      let(:purchase_price_cents) { 123 }

      it do
        post "/operator/api/v1/nomenclatures/#{nomenclature.id}/receipt", params: { quantity: receipt_quantity, purchase_price_cents: purchase_price_cents }

        expect(response.status).to eq 201

        expect(nomenclature.reload.quantity).to eq(receipt_quantity)

        post "/operator/api/v1/nomenclatures/#{nomenclature.id}/expense", params: { quantity: expense_quantity }

        expect(response.status).to eq 201

        expect(nomenclature.reload.quantity).to eq(receipt_quantity - expense_quantity)
      end
    end
  end
end
