require 'rails_helper'

describe YandexKassa::PaymentService do
  subject { described_class.new vendor: vendor, params: params }

  let(:vendor) { create :vendor, :yandex_kassa }

  context 'correct payment' do
    let(:order)  { create :order, :items, vendor: vendor }

    let(:params) do
      {
        orderNumber: '116',
        orderSumAmount: '10.00',
        orderSumCurrencyPaycash: '10643',
        orderSumBankPaycash: '1003',
        invoiceId: '2000000796577',
        customerNumber: '1',
        requestDatetime: '2016-05-30T12:41:08.235+03:00',
        shopId: '53082',
        md5: 'C0DAF116E6D09D27A96A4AFCD79E8111',
        action: 'paymentAviso'
      }
    end

    before do
      allow(Order).to receive(:find_by_id).with('116').and_return order
    end

    it 'return complete' do
      expect(subject.perform_and_get_response.to_xml).to include 'code="0"'

      expect(order.order_payment.state).to eq OrderPayment::STATE_PAID
      expect(order.workflow_state).to be_working
    end
  end
end
