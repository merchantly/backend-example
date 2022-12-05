require 'rails_helper'

describe Billing::CloudPaymentsRecurrentCharge do
  # let(:valid_token) { '2F725BBD1F405A1ED0336ABAF85DDFEB6902A9984A76FD877C3B5CC3B5085A82' }
  # let(:invalid_token) { 'ABBEF19476623CA56C17DA75FD57734DBF82530686043A6E491C6D71BEFE8F6E' }

  subject { described_class.new(invoice: invoice, payment_account: payment_account) }

  let(:vendor) { create :vendor }
  let(:account) { vendor.common_billing_account }
  let(:amount) { Money.new(5053, account.amount_currency) }
  let(:invoice) { create :openbill_invoice, destination_account: account, amount: amount }
  let(:cloud_payments_transaction) { build_stubbed :cloud_payments_transaction, invoice_id: invoice.id, account_id: account.id }

  let(:payment_account) { create :payment_account, vendor: vendor, gateway: Billing::CLOUDPAYMENTS_GATEWAY_KEY }

  describe do
    let(:response) { cloud_payments_transaction }

    it do
      expect_any_instance_of(CloudPayments::Namespaces::Tokens).to receive(:charge).and_return response
      expect(Billing::IncomeFromCloudPayments).to receive(:perform).and_call_original

      subject.call
    end
  end

  describe '#call' do
    it 'Нет денег' do
      expect_any_instance_of(CloudPayments::Namespaces::Tokens).to receive(:charge).and_raise CloudPayments::Client::GatewayErrors::InsufficientFunds
      expect_any_instance_of(Vendor).to receive(:notify).and_call_original
      subject.call
    end

    it 'фатальная ошибка от cloudpayments' do
      expect_any_instance_of(CloudPayments::Namespaces::Tokens).to receive(:charge).and_raise CloudPayments::Client::GatewayErrors::Invalid
      expect_any_instance_of(Vendor).to receive(:notify).and_call_original

      subject.call
    end

    context 'Amount is greater than allowed' do
      let(:amount) { Billing::CloudPaymentsRecurrentCharge::MAX_SUBTRACT_SUM + 10.to_money(account.amount_currency) }

      it 'must raise error' do
        expect { subject.call }.to raise_error Billing::CloudPaymentsRecurrentCharge::LargeAmountError
      end
    end
  end
end
