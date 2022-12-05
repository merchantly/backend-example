require 'rails_helper'

describe PayPal::PaymentService::Notify do
  subject { described_class.new params, vendor }

  let(:vendor) { create :vendor }
  let(:order)  { create :order, vendor: vendor }

  let(:params) do
    {
      'payment_status' => 'Completed',
      'custom' => '{"order_amount": "10.00", "order_id": 538}'
    }
  end

  before do
    allow(vendor.orders).to receive(:find_by_id).with(538).and_return order
  end

  it { expect(subject.vendor).to eq vendor }
  it { expect(subject.valid?).to eq true }
  it { expect(subject.accepted?).to eq true }
  it { expect(subject.order).to eq order }
end
