require 'rails_helper'

RSpec.describe System::PaymentsController, type: :controller do
  render_views

  let(:vendor) { create :vendor }
  let(:account) { vendor.common_billing_account }
  let(:invoice) { create :openbill_invoice, destination_account: account }
  let(:cloud_payments_transaction) { build_stubbed :cloud_payments_transaction, invoice_id: invoice.id, account_id: account.id }

  describe 'POST pay' do
    context 'invalid form' do
      it 'returns http success' do
        post :pay, params: { id: invoice.id, cloud_payments_form: { name: 'asdf' } }

        expect(response).to be_ok
        expect(response).to render_template('system/invoices/show')
      end
    end

    context 'карта с 3Ds' do
      let(:cp_response) do
        CloudPayments::Secure3D.new(
          transaction_id: 19_292_207,
          pa_req: '+/eyJNZXJjaGFudE5hbWUiOm51bGwsIkZpcnN0U2l4IjoiNDI0MjQyIiwiTGFzdEZvdXIiOiI0MjQyIiwiQW1vdW50IjoxLjAsIkN1cnJlbmN5Q29kZSI6IlJVQiIsIkRhdGUiOiIyMDE3LTA4LTI3VDAwOjAwOjAwKzAzOjAwIiwiQ3VzdG9tZXJOYW1lIjpudWxsLCJDdWx0dXJlTmFtZSI6InJ1LVJVIn0=',
          acs_url: 'https://demo.cloudpayments.ru/acs'
        )
      end

      it 'returns http success' do
        expect(cp_response).to be_required_secure3d
        expect_any_instance_of(CloudPayments::Namespaces::Cards).to receive(:charge).and_return cp_response
        post :pay, params: { id: invoice.id, cloud_payments_form: { name: 'asdf', cryptogram_packet: 'some' } }

        expect(response).to be_ok
        expect(response).to render_template('system/payments/form3ds')
      end
    end

    context 'Карта без 3Ds. На карте есть деньги' do
      it 'redirect' do
        expect(cloud_payments_transaction).not_to be_required_secure3d
        expect_any_instance_of(CloudPayments::Namespaces::Cards).to receive(:charge).and_return cloud_payments_transaction
        expect_any_instance_of(Vendor).to receive(:save_payment_card).and_call_original

        post :pay, params: { id: invoice.id, cloud_payments_form: { name: 'asdf', recurrent: true, cryptogram_packet: 'some' } }

        expect(response).to be_redirection
        expect(response).to redirect_to success_system_payment_url(invoice.id)
      end
    end

    context 'Карта без 3Ds. На карте нет денег' do
      it do
        expect(cloud_payments_transaction).not_to be_required_secure3d
        expect_any_instance_of(CloudPayments::Namespaces::Cards).to receive(:charge).and_raise CloudPayments::Client::GatewayErrors::InsufficientFunds
        expect(Billing::IncomeFromCloudPayments).not_to receive(:perform)

        post :pay, params: { id: invoice.id, cloud_payments_form: { name: 'asdf', cryptogram_packet: 'some' } }

        expect(response).to be_ok
        expect(response).to render_template('system/invoices/show')
        expect(response.body).to include I18n.t('errors.cloud_payments.InsufficientFunds')
      end
    end
  end

  describe 'POST post3ds' do
    it 'удачная оплата' do
      expect_any_instance_of(CloudPayments::Namespaces::Payments).to receive(:post3ds).with('123', '123').and_return cloud_payments_transaction
      expect(Billing::IncomeFromCloudPayments).to receive(:perform).with(cloud_payments_transaction).and_call_original

      expect_any_instance_of(Vendor).to receive(:save_payment_card).and_call_original
      post :post3ds, params: { id: invoice.id, 'MD' => 123, 'PaRes' => 123, recurrent: true }

      expect(response).to be_redirection
      expect(response).to redirect_to success_system_payment_url(invoice.id)
    end

    it 'нет денег' do
      expect_any_instance_of(CloudPayments::Namespaces::Payments).to receive(:post3ds)
        .with('123', '123')
        .and_raise CloudPayments::Client::GatewayErrors::InsufficientFunds

      expect(Billing::IncomeFromCloudPayments).not_to receive(:perform)

      post :post3ds, params: { id: invoice.id, 'MD' => 123, 'PaRes' => 123 }

      expect(response).to be_ok
      expect(response).to render_template('system/invoices/show')
      expect(response.body).to include('Недостаточно средств на карте')
    end
  end

  describe 'GET success' do
    it do
      get :success, params: { id: invoice.id }
      expect(response).to be_ok
      expect(response).to render_template('system/payments/success')
    end
  end
end
