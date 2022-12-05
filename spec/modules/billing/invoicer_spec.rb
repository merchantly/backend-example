require 'rails_helper'

describe Billing::Invoicer do
  let(:tariff) { create :tariff }
  let(:month_amount) { tariff.month_price }

  describe 'specific vendor' do
    let(:vendor) { create :vendor, tariff: tariff, paid_to: paid_to, working_to: working_to }
    let(:paid_to) { Date.current }
    let(:working_to) { Date.current }

    let(:object) { described_class.new vendor: vendor, date: DateTime.current }

    context 'next month invoice' do
      subject { object.create_next_month_invoice }

      it do
        expect(subject).to be_a(OpenbillInvoice)
        expect(subject.amount).to eq month_amount
      end
    end

    context '' do
      subject { object.create_negative_balance_invoice }

      let(:amount) { Money.new 10_200 }

      before do
        create :openbill_transaction,
               from_account: vendor.common_billing_account,
               to_account_id: Billing::SYSTEM_ACCOUNTS[:subscriptions],
               amount: amount

        vendor.common_billing_account.reload
      end

      it do
        expect(subject).to be_a(OpenbillInvoice)
        expect(subject.amount).to eq amount
      end
    end
  end
end
