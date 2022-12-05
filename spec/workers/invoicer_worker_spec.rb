require 'rails_helper'

describe InvoicerWorker do
  let_it_be(:tariff) { create :tariff }
  let(:month_amount) { tariff.month_price }

  context 'find shop for next month invoice' do
    subject { described_class.new.perform }

    let(:working_to) { Date.current + 10 }
    let!(:vendor1) { create :vendor, tariff: tariff, paid_to: Date.current, working_to: working_to }
    let!(:vendor2) { create :vendor, tariff: tariff, paid_to: Date.current + 10, working_to: working_to }
    let!(:vendor3) { create :vendor, tariff: tariff, paid_to: nil, working_to: working_to }
    let!(:vendor4) { create :vendor, tariff: tariff, paid_to: nil, working_to: nil }

    before :all do
      Vendor.destroy_all
    end

    before do
      create :openbill_transaction,
             from_account: vendor4.common_billing_account,
             to_account_id: Billing::SYSTEM_ACCOUNTS[:subscriptions],
             amount: 10_000.to_money(:rub)
    end

    it do
      expect(Billing::Invoicer).to receive(:create_next_month_invoice).with(vendor: vendor1, is_autochargable: true).and_call_original
      expect(Billing::Invoicer).to receive(:create_next_month_invoice).with(vendor: vendor3, is_autochargable: true).and_call_original
      expect(Billing::Invoicer).to receive(:create_negative_balance_invoice).with(vendor: vendor4).and_call_original
      subject
    end
  end
end
