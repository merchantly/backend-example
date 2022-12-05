require 'rails_helper'

describe PayPal::PaymentService do
  subject { described_class.new vendor: vendor, params: params }

  let(:vendor) { create :vendor }

  context 'correct payment' do
    let(:order)  { create :order, vendor: vendor }

    let(:params) do
      {
        'payment_status' => 'Completed',
        'custom' => "{\"order_amount\": \"#{order.total_with_delivery_price}\", \"order_id\": #{order.id}}"
      }
    end

    it 'return complete' do
      expect(subject.perform_and_get_response).to include 'complete'

      expect(order.order_payment.state).to eq OrderPayment::STATE_PAID
      expect(order.workflow_state).to be_working
    end
  end
end
