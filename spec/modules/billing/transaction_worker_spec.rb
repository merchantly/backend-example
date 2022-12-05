require 'rails_helper'

describe Billing::TransactionWorker, sidekiq: :inline do
  subject { described_class.new }

  let(:amount) { Money.new 10_000 }
  let(:billing_account) { vendor.common_billing_account }
  let(:invoice) { create :openbill_invoice, destination_account: billing_account, amount: amount, meta: { service: Billing::Invoicer::SERVICE_COMMON, tariff_id: tariff.id } }
  let(:openbill_transaction) do
    ot = build :openbill_transaction,
               from_account: cloudpayment_account,
               to_account: billing_account,
               amount: amount,
               invoice: invoice,
               meta: {
                 vendor_id: vendor.id
               }
    allow(ot).to receive(:perform_worker).and_return true
    ot.save!
    ot
  end
  let(:tariff) { create :tariff, month_price: amount }

  let_it_be(:cloudpayment_account) { create :openbill_account }

  context 'Магазин без тарифа' do
    let!(:vendor) { create :vendor, tariff_id: nil, paid_to: nil, working_to: nil }

    specify do
      expect(subject).not_to receive(:support_email)
      subject.perform openbill_transaction.id
      vendor.reload

      expect(vendor.paid_to).to eq Date.current.next_month
      expect(vendor.working_to).to be > vendor.paid_to
      expect(vendor.tariff).to eq tariff
    end
  end

  context 'Магазин с другим тарифом и установленным paied_to' do
    let(:current_paid_to) { Date.current + 5.days }
    let(:old_tariff)      { create :tariff }
    let!(:vendor)         { create :vendor, tariff: old_tariff, paid_to: current_paid_to, working_to: current_paid_to }

    specify do
      subject.perform openbill_transaction.id

      vendor.reload

      expect(vendor.paid_to).to eq current_paid_to.next_month
      expect(vendor.working_to).to be > vendor.paid_to
      expect(vendor.tariff).to eq tariff
    end
  end

  context 'В магазин приходит оплата без invoice-а' do
    let(:current_paid_to) { Date.current + 5.days }
    let!(:vendor)         { create :vendor, tariff: tariff, paid_to: current_paid_to, working_to: current_paid_to }

    let(:openbill_transaction) do
      ot = build :openbill_transaction,
                 from_account: cloudpayment_account,
                 to_account: billing_account,
                 amount: amount,
                 meta: {
                   vendor_id: vendor.id
                 }
      allow(ot).to receive(:perform_worker).and_return true
      ot.save!
      ot
    end

    specify do
      subject.perform openbill_transaction.id
      vendor.reload

      expect(vendor.paid_to).to eq current_paid_to.next_month
      expect(vendor.working_to).to be > vendor.paid_to
      expect(vendor.tariff).to eq tariff
    end
  end

  context 'Оплата за SMS' do
    let!(:vendor) { create :vendor, tariff_id: nil, paid_to: nil, working_to: nil }
    let(:sms_count) { 12 }
    let(:invoice) do
      create :openbill_invoice,
             destination_account: billing_account,
             amount: amount,
             meta: { service: Billing::Invoicer::SERVICE_SMS, sms_count: sms_count }
    end

    it do
      expect(vendor.common_billing_account.amount).to eq 0
      expect(vendor.common_billing_account.all_transactions.count).to eq 0
      expect(vendor.vendor_sms_incomes.count).to eq 0
    end

    specify do
      subject.perform openbill_transaction.id
      vendor.reload
      expect(vendor.common_billing_account.amount).to eq 0
      expect(vendor.common_billing_account.all_transactions.count).to eq 2
      expect(vendor.vendor_sms_incomes.count).to eq 1
    end
  end
end
