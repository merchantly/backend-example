require 'rails_helper'

describe W1::OrderDeliveryService do
  let(:order)  { create :order, :delivery_redexpress }
  let(:vendor) { order.vendor }

  let!(:service) { described_class.new order }

  before do
    stub_request(:post, W1::API_CHECKOUT_URL)
      .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Host' => 'www.walletone.com' })
      .to_return(File.new('./spec/fixtures/w1/delivery_success.raw'))

    stub_request(:get, 'https://www.walletone.com/checkout/Default.aspx?i=347632066531&m=127696943127')
      .to_return(File.new('./spec/fixtures/w1/success_delivery_redirect.raw'))

    # Редирект на редирект из ./spec/fixtures/w1/success_delivery_redirect.raw
    stub_request(:get, 'https://www.walletone.com/checkout/Login.aspx?i=347632066531&m=127696943127&pt=RedExpressRUB-RedCashRUB')
  end

  it 'изначально заказ новый' do
    expect(order.order_delivery.state).to eq OrderDelivery::STATE_NEW
  end

  it do
    expect(order.order_payment.external_id).to be_blank
  end

  describe 'редирект с не абсолютным путем' do
    subject { service.send(:add_host_if_need, uri) }

    let(:uri) { Addressable::URI.parse url }

    context do
      let(:url) { '/checkout/State.aspx?m=105981838491&i=344425426393&pt=AssistRUB-CreditCardRUB' }

      it { expect(subject).to eq "https://www.walletone.com#{url}" }
    end

    context do
      let(:url) { 'https://www.walletone.com/checkout/Default.aspx?i=347632066531&m=127696943127' }

      it { expect(subject.to_s).to eq url }
    end
  end

  # https://www.walletone.com/checkout/Login.aspx?i=347632066531&m=127696943127&pt=RedExpressRUB-RedCashRUB
  #
  describe 'check response to catch test fails' do
    subject { service.send(:make_response) }

    let(:result) { '<html><head><title>Object moved</title></head><body><h2>Object moved to <a href="https://www.walletone.com/checkout/Default.aspx?i=347632066531&amp;m=127696943127">here</a>.</h2>; </body></html>' }

    it { expect(subject.code).to eq '302' }
    it { expect(subject.body).to eq result }
  end

  describe '#create' do
    before do
      service.create
    end

    it do
      expect(order.order_payment.external_id).to be_present
    end
  end

  it { expect(service).to receive(:info).once; service.create }
  it { expect(service).to receive(:debug).exactly(4).times; service.create }
  it { expect(service).not_to receive(:error); service.create }
end

# на body не проверяем потому что он сложный
# но структура пусть тут лежит чтобы видно было что ждем
# let(:request_body) { { "WMI_CURRENCY_ID"=>"643",
# "WMI_CUSTOMER_EMAIL"=>"test@test.ru",
# "WMI_DELIVERY_ADDRESS"=>"Адрес",
# "WMI_DELIVERY_CITY"=>"Город номер 2",
# "WMI_DELIVERY_COMMENTS"=>"ТЕСТОВЫЙ ЗАКАЗ. НЕ ВЫПОЛНЯТЬ!",
# "WMI_DELIVERY_CONTACTINFO"=>"+79033891228",
# "WMI_DELIVERY_COUNTRY"=>"Россия",
# "WMI_DELIVERY_ORDERID"=>"kiosk-1test",
# "WMI_DELIVERY_REQUEST"=>"1",
# "WMI_DELIVERY_SKIPINSTRUCTION"=>"1",
# "WMI_DESCRIPTION"=>"Тестовый платеж!",
# "WMI_FAIL_URL"=>"http://kompaniya-1.korm.test:3000/payments/w1/failure",
# "WMI_MERCHANT_ID"=>vendor.w1_merchant_id,
# "WMI_PAYMENT_AMOUNT"=>"300.00",
# "WMI_PAYMENT_NO"=>"1",
# "WMI_PTENABLED"=>"CreditCardRUB",
# "WMI_SIGNATURE"=>"B22mlHtV2R29ftng2ysRqA==",
# "WMI_SUCCESS_URL"=>"http://kompaniya-1.korm.test:3000/payments/w1/success"} }
