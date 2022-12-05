require 'rails_helper'

describe YandexKassa::PaymentService::Notify do
  subject { described_class.new params, vendor }

  let(:vendor) { create :vendor }
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
      md5: '78C71D69507EBFDAFFF42E9508F9BA88',
      action: 'checkOrder'
    }
  end

  before do
    allow(Order).to receive(:find_by_id).with('116').and_return order
  end

  it { expect(subject.vendor).to eq vendor }
  it { expect(subject.accepted?).to eq true }
  it { expect(subject.order).to eq order }
end
