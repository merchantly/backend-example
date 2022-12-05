require 'rails_helper'

RSpec.describe OrderWalletone, type: :model do
  subject { Order.parse_external_id number }

  let!(:id)    { 123 }
  let!(:order) { build :order, id: id }

  context 'broken' do
    let(:number) { 'kiosk--1157' }

    it do
      expect { subject }.to raise_error(OrderWalletone::WrongNumberFormat)
    end
  end

  context do
    let(:number) { 'kiiiosk:12-27' }

    it do
      vendor_id, order_id = subject
      expect(vendor_id.to_i).to eq 12
      expect(order_id.to_i).to eq 27
    end
  end

  context do
    let(:number) { 'kiosk:5-1157-' }

    it do
      vendor_id, order_id = subject
      expect(vendor_id.to_i).to eq 5
      expect(order_id.to_i).to eq 1157
    end
  end

  context do
    let(:number) { 'kiosk:5-1157-pro' }

    it do
      vendor_id, order_id = subject
      expect(vendor_id.to_i).to eq 5
      expect(order_id.to_i).to eq 1157
    end
  end
end
