require 'rails_helper'

describe RbkMoney::PaymentService do
  subject { described_class.new vendor: vendor, params: params, headers: headers, data: params.to_param }

  let(:vendor) { create :vendor, :with_rbk_money }

  context 'correct payment' do
    let(:order) { create :order, :items, vendor: vendor }

    let(:params) do
      {
        eventID: 2_006_462,
        eventType: 'PaymentProcessed',
        invoice: {
          amount: 8500,
          createdAt: '2017-09-27T16:25:35.995166Z',
          currency: 'RUB',
          description: 'Изысканная кухня',
          dueDate: '2018-10-28T16:25:35Z',
          id: 'u7wzxUVbZg',
          metadata: {
            order_id: order.id
          },
          product: 'Заказ №12345',
          shopID: 'TEST',
          status: 'unpaid'
        },
        occuredAt: '2017-09-27T16:25:37.505396Z',
        payment: {
          amount: 8500,
          contactInfo: {
            email: 'hungry-man@email.ru'
          },
          createdAt: '2017-09-27T16:25:36.876168Z',
          currency: 'RUB',
          fingerprint: '1f595464b38a9276b6ab61399417a5c3',
          id: '1',
          ip: '2A04:4A00:5:1014::100D',
          paymentSession: '5CNNzitToqjmpuEajuOKnG',
          paymentToolToken: '7TjB6PA3CZtdHLTjVD1Pig',
          status: 'processed'
        },
        topic: 'InvoicesTopic'
      }
    end

    let(:headers) do
      {
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': 706,
        Host: 'localhost:8088',
        Connection: 'Keep-Alive',
        'Accept-Encoding': 'gzip',
        'User-Agent': 'okhttp/3.6.0'
      }
    end

    it 'return complete' do
      pkey = OpenSSL::PKey::RSA.new 2048

      vendor.update rbk_money_public_key: pkey.public_key.to_s

      digest = Base64.encode64(pkey.sign(OpenSSL::Digest.new('sha256'), params.to_param)).strip

      headers['Content-Signature'] = "alg=RS256; digest=#{digest}"

      expect(subject.perform_and_get_response).to eq 'OK'

      expect(order.order_payment.state).to eq OrderPayment::STATE_PAID
      expect(order.workflow_state).to be_working
    end
  end
end
