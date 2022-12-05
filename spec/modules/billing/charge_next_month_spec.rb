require 'rails_helper'

describe Billing::ChargeNextMonth, sidekiq: :inline do
  let_it_be(:partner_coupon) { create :partner_coupon }
  let_it_be(:partner) { partner_coupon.partner }

  let(:amount) { 100.to_money }
  let(:date) { Date.current }
  let(:subkey) { 'test' }
  let(:meta) { {} }
  let(:next_paid_to) { nil }
  let(:months_count) { 1 }

  let(:invoicer) do
    described_class.new(
      vendor: vendor,
      amount: amount,
      date: date,
      subkey: subkey,
      meta: meta,
      next_paid_to: next_paid_to,
      months_count: months_count,
      invoice: invoice
    )
  end

  context do
    let(:vendor) { create :vendor, paid_to: paid_to, working_to: working_to, partner_coupon_code: partner_coupon.code }
    let(:invoice) { create :openbill_invoice, destination_account: vendor.common_billing_account }
    let(:paid_to) { nil }
    let(:working_to) { nil }

    it 'для начала' do
      expect(vendor.paid_to).to be_nil
      expect(vendor.working_to).to be_nil
    end

    specify do
      expect(Billing::Partner::IncomeReward).to receive(:new).and_call_original
      expect_any_instance_of(VendorNotificationService).to receive(:partner_incoming).and_call_original
      # У вендора изменились paid_to
      # Появилась соответсвующая транзация
      invoicer.charge!

      vendor.reload
      expect(vendor.paid_to).to eq Date.current.next_month months_count
      expect(vendor.working_to).not_to be_nil
      expect(vendor.working_to).to be >= vendor.paid_to
    end
  end
end
