require 'rails_helper'

describe SystemAPI::PaymentsCallbacks do
  let!(:vendor) { create :vendor, :with_rbk_money }
  let(:order) { create :order, :items, vendor: vendor }

  before do
    host! 'api.example.com'
  end

  describe 'POST /v1/callbacks/w1/payments/:vendor_id/notify' do
    context 'encoding cp1251' do
      let(:params) do
        {
          'WMI_PAYMENT_NO' => order.external_id,
          'WMI_MERCHANT_ID' => '105981838491',
          'WMI_PAYMENT_AMOUNT' => '2230.00',
          'WMI_DESCRIPTION' => 'Браслет с черным жемчугом Подвеска Himére (Браслет с черным жемчугом Himére)'.encode!(Encoding::Windows_1251, invalid: :replace, undef: :replace),
          'WMI_CURRENCY_ID' => '643',
          'WMI_SUCCESS_URL' => 'http%3A%2F%2Fsaharokstore.ru%2Fpayments%2Fw1%2Fsuccess',
          'WMI_FAIL_URL' => 'http%3A%2F%2Fsaharokstore.ru%2Fpayments%2Fw1%2Ffailure',
          'WMI_PTENABLED' => 'RedCashRUB',
          'WMI_CUSTOMER_EMAIL' => 'asdf%40gmail.com',
          'WMI_DELIVERY_DATEFROM' => '17.09.2015+09%3A00%3A00',
          'WMI_DELIVERY_DATETILL' => '17.09.2015+18%3A00%3A00',
          'WMI_DELIVERY_REQUEST' => '1',
          'WMI_DELIVERY_COUNTRY' => 'Россия'.encode!(Encoding::Windows_1251, invalid: :replace, undef: :replace),
          'WMI_DELIVERY_CITY' => '%D0%9C%D0%BE%D1%81%D0%BA%D0%B2%D0%B0',
          'WMI_DELIVERY_ADDRESS' => '%D0%9B%D0%B5%D0%BD%D0%B8%D0%BD%D0%B3%D1%80%D0%B0%D0%B4%D1%81%D0%BA%D0%BE%D0%B5+%D1%88%D0%BE%D1%81%D1%81%D0%B5%2C+71+%D0%93+%D1%81%D1%82%D1%80+2',
          'WMI_DELIVERY_CONTACTINFO' => '%2B79686086013',
          'WMI_DELIVERY_COMMENTS' => '%D0%B1%D1%83%D0%B4%D0%BD%D0%B8%D0%B9+%D0%B4%D0%B5%D0%BD%D1%8C+%D1%81+9+%D0%B4%D0%BE+18',
          'WMI_DELIVERY_ORDERID' => order.external_id,
          'WMI_DELIVERY_SKIPINSTRUCTION' => '1',
          'WMI_ORDER_STATE' => 'Accepted'
        }
      end

      let(:params_with_signature) do
        params.merge('WMI_SIGNATURE' => W1.generate_signature_from_options(params, vendor.vendor_walletone.merchant_sign_key))
      end

      let(:result) do
        'WMI_RESULT=OK'
      end

      # lib/utf8_sanitizer_with_exclusions.rb
      it 'Rack::UTF8Sanitizer ничего не ломает' do
        post "/v1/callbacks/w1/payments/#{vendor.id}/notify", params: params_with_signature

        assert_equal response.status, 201
        assert_equal response.body, result, 'Результат должен быть OK, если Rack::UTF8Sanitizer ничего не трогал'
      end
    end

    context 'битые параметры' do
      let(:params) { { WMI_PAYMENT_NO: '123' } }

      let(:result) do
        'WMI_RESULT=RETRY&WMI_DESCRIPTION=%D0%92%D0%BD%D1%83%D1%82%D1%80%D0%B5%D0%BD%D0%BD%D1%8F%D1%8F+%D0%BE%D1%88%D0%B8%D0%B1%D0%BA%D0%B0+BasePaymentService%3A%3ANoSignature'
      end
      # У wanna-be в WalletOne прописан такой url:
      # http://api.kiiiosk.store/v1/callbacks/w1/payments/5/notify

      it do
        post "/v1/callbacks/w1/payments/#{vendor.id}/notify", params: params

        assert_equal response.status, 201
        assert_equal response.body, result, 'Результат должен быть retry, потому что мы кинули левые params'
      end
    end

    context 'Пришли странные данные' do
      let(:notify_params) { {} }
      let(:wps_response) { SecureRandom.hex }

      # WMI_RESULT=RETRY&WMI_DESCRIPTION=%D0%9F%D0%BB%D0%B0%D1%82%D0%B5%D0%B6+%D0%BD%D0%B5+%D0%B2%D0%B0%D0%BB%D0%B8%D0%B4%D0%BD%D1%8B%D0%B9+%D0%B8%D0%BB%D0%B8+%D0%BD%D0%B5+%D0%BF%D0%BE%D0%BB%D0%BD%D1%8B%D0%B9"
      it do
        allow_any_instance_of(W1::PaymentService).to receive(:perform_and_get_response)
          .and_return(wps_response)

        post "/v1/callbacks/w1/payments/#{vendor.id}/notify", params: notify_params

        expect(response.body).to eq wps_response
      end
    end
  end

  describe 'POST /v1/callbacks/pay_pal/payments/:vendor_id/notify' do
    let(:params) do
      {
        'payment_status' => 'Completed',
        'custom' => "{\"order_amount\": \"10.00\", \"order_id\": #{order.id}}"
      }
    end

    let(:result) do
      'complete'
    end

    it do
      post "/v1/callbacks/pay_pal/payments/#{vendor.id}/notify", params: params

      assert_equal response.status, 201
      assert_equal response.body, result
    end
  end

  # см ./doc/yandex.kassa.md
  describe 'POST /v1/callbacks/yandex/payments/:vendor_id/' do
    let(:params) do
      {
        orderNumber: '116',
        orderSumAmount: '10.00',
        orderSumCurrencyPaycash: '10643',
        orderSumBankPaycash: '1003',
        invoiceId: '2000000796577',
        customerNumber: '1',
        requestDatetime: '2016-05-30T12:41:08.235+03:00',
        shopId: '53082'
      }
    end
    let(:check_md5) { '78C71D69507EBFDAFFF42E9508F9BA88' }
    let(:check_action) { 'checkOrder' }
    let(:aviso_md5) { 'C0DAF116E6D09D27A96A4AFCD79E8111' }
    let(:aviso_action) { 'paymentAviso' }

    before do
      allow(Order).to receive(:find_by_id).with('116').and_return order
    end

    it 'notify return status 200' do
      post "/v1/callbacks/yandex/payments/#{vendor.id}/notify", params: params.merge(md5: aviso_md5, action: aviso_action)

      assert_equal 200, response.status
      expect(response.content_type).to eq 'application/xml'
      expect(response.body).to include 'code="0"'
    end

    it 'check return status 200' do
      post "/v1/callbacks/yandex/payments/#{vendor.id}/check", params: params.merge(md5: check_md5, action: check_action)

      assert_equal 200, response.status
      expect(response.content_type).to eq 'application/xml'
      # Пример ответа "<?xml version=\"1.0\"?>\n" + "<checkOrderResponse code=\"0\" performedDatetime=\"2016-05-30T12:41:08.235+03:00\" invoiceId=\"2000000796577\" shopId=\"53082\"/>\n"
      expect(response.body).to include 'code="0"'
    end
  end

  describe 'POST /v1/callbacks/rbk_money/payments/:vendor_id/notify.json' do
    let(:params) do
      {
        'eventType' => 'PaymentProcessed',
        'invoice' => {
          'metadata' => {
            'order_id' => '116'
          },
          'product' => 'Заказ №12345',
          'shopID' => 'TEST',
          'status' => 'unpaid'
        },
        'occuredAt' => '2017-09-27T16:25:37.505396Z',
        'payment' => {
          'amount' => '8500',
        },
        'topic' => 'InvoicesTopic'
      }
    end
    let(:data) do
      'invoice[metadata][order_id]=116&invoice[product]=%D0%97%D0%B0%D0%BA%D0%B0%D0%B7+%E2%84%9612345&invoice[shopID]=TEST&invoice[status]=unpaid&occuredAt=2017-09-27T16%3A25%3A37.505396Z&payment[amount]=8500&topic=InvoicesTopic'
    end

    before do
      allow(Order).to receive(:find_by_id).with('116').and_return order
    end

    it do
      expect(order.paid?).to eq false

      pkey = OpenSSL::PKey::RSA.new 2048

      vendor.update rbk_money_public_key: pkey.public_key.to_s

      digest = Base64.encode64(pkey.sign(OpenSSL::Digest.new('sha256'), data)).strip

      post "/v1/callbacks/rbk_money/payments/#{vendor.id}/notify", params: params, headers: { 'Content-Signature': "alg=RS256; digest=#{digest}" }

      assert_equal response.status, 200
      assert_equal response.body, 'OK'
      expect(order.reload.paid?).to eq true
    end
  end

  describe 'POST /v1/callbacks/cloud_payments/:vendor_id/pay' do
    let(:transaction_id) { 123 }
    let!(:vendor_payment) { create :vendor_payment, vendor: vendor, payment_agent_type: OrderPaymentCloudPayments.name, cloud_payments_public_id: '123', cloud_payments_api_key: '123' }
    let(:params) do
      {
        'TransactionId' => '19365629',
        'Amount' => '500.00',
        'Currency' => 'RUB',
        'PaymentAmount' => '500.00',
        'PaymentCurrency' => 'RUB',
        'InvoiceId' => order.external_id,
        'AccountId' => 'aa477b74-ac08-4562-a186-c58b83da86a7',
        'SubscriptionId' => '',
        'Name' => '123',
        'Email' => '',
        'DateTime' => '2017-08-28 17:17:35',
        'IpAddress' => '46.73.130.128',
        'IpCountry' => 'RU',
        'IpCity' => 'Москва',
        'IpRegion' => 'Москва',
        'IpDistrict' => 'Центральный федеральный округ',
        'IpLatitude' => '55.755787',
        'IpLongitude' => '37.617634',
        'CardFirstSix' => '424242',
        'CardLastFour' => '4242',
        'CardType' => 'Visa',
        'CardExpDate' => '01/18',
        'Issuer' => '',
        'IssuerBankCountry' => '',
        'Description' => 'Оплата обслуживания интернет магазина http://wannabe.3001.brandymint.ru',
        'AuthCode' => 'A1B2C3',
        'Token' => '477BBA133C182267FE5F086924ABDC5DB71F77BFC27F01F2843F2CDC69D89F05',
        'TestMode' => '1',
        'Status' => 'Completed'
      }
    end

    context 'pay' do
      specify do
        expect(order).not_to be_paid
        expect(order.order_payment).to be_new
        expect_any_instance_of(CloudPayments::Webhooks).to receive(:validate_data!)
        expect_any_instance_of(CloudPayments::Webhooks).to receive(:on_pay).and_call_original

        post "/v1/callbacks/cloud_payments/#{vendor.id}/pay", params: params

        assert_equal response.body, '{"code":0}'

        order.reload
        expect(order.order_payment).to be_paid
        expect(order).to be_paid
      end
    end

    context 'fail' do
      specify do
        expect(order).not_to be_paid
        expect(order.order_payment).to be_new
        expect_any_instance_of(CloudPayments::Webhooks).to receive(:validate_data!)
        expect_any_instance_of(CloudPayments::Webhooks).to receive(:on_fail).and_call_original

        post "/v1/callbacks/cloud_payments/#{vendor.id}/fail", params: params.merge('Status' => 'Incompleted', 'Reason' => 'Unknown', 'ReasonCode' => 0)

        assert_equal response.body, '{"code":0}'
        order.reload

        expect(order.order_payment).to be_failed
        expect(order).not_to be_paid
      end
    end
  end
end
