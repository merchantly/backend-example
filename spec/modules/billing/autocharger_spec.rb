require 'rails_helper'

describe Billing::Autocharger do
  subject { described_class.new(invoice: invoice) }

  let(:invoice_amount) { Money.new(490_00, :rub) }
  let(:invoice) { create :openbill_invoice, amount: invoice_amount, destination_account: vendor.common_billing_account }

  context do
    let(:vendor) { create :vendor }

    it 'не хватает средств, карты для рекурентного снятия нету' do
      expect_any_instance_of(Billing::CloudPaymentsRecurrentCharge).not_to receive(:call)
      expect_any_instance_of(VendorNotificationService).to receive(:need_payment)

      subject.call
    end
  end

  context 'рекурентная карта привязана, баланс 0' do
    let(:vendor) { create :vendor, :with_payment_account }
    let(:tariff_amount) { Money.new(490_00, :rub) }

    it 'рекурентно пополняем' do
      expect_any_instance_of(Billing::CloudPaymentsRecurrentCharge).to receive(:call) do
        OpenbillTransaction.create!(
          from_account_id: Billing::CLOUDPAYMENTS_ACCOUNT_ID,
          to_account: vendor.common_billing_account,
          date: Date.current,
          key: "recurrent:#{Date.current}",
          amount: tariff_amount,
          details: '123',
          meta: {}
        )
      end

      expect_any_instance_of(VendorNotificationService).not_to receive(:need_payment)

      subject.call
    end
  end

  context 'на внутреннем счету достаточно средств, списываем с него' do
    let(:vendor) { create :vendor, :with_payment_account }
    let(:account_amount) { Money.new(100_000, :rub) }

    before do
      OpenbillTransaction.create!(
        from_account_id: Billing::CLOUDPAYMENTS_ACCOUNT_ID,
        to_account: vendor.common_billing_account,
        date: Date.current,
        key: "recurrent:#{Date.current}",
        amount: account_amount,
        details: '123',
        meta: {}
      )
      vendor.reload
    end

    it 'рекурентно пополняем' do
      expect(vendor.common_billing_account.amount).to eq account_amount
      expect_any_instance_of(VendorNotificationService).not_to receive(:need_payment)
      expect_any_instance_of(Billing::ChargeNextMonth).to receive(:charge!).and_call_original

      subject.call

      vendor.reload
      expect(vendor.common_billing_account.amount).to eq account_amount - invoice_amount
    end
  end
end
