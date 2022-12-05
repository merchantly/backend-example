require 'rails_helper'

describe VendorNotificationService do
  include CurrentVendor

  subject { described_class.new vendor }

  let(:tariff) { create :tariff }
  let(:to_account) do
    double amount: Money.new(1)
  end
  let(:from_account) do
    double amount: Money.new(1)
  end
  let(:transaction) do
    double id: '123', amount: Money.new(1, :rub), details: '123', to_account: to_account, from_account: from_account
  end
  let(:order)  { create :order }
  let(:vendor) { order.vendor }

  let(:invoice) do
    create :openbill_invoice, destination_account: vendor.common_billing_account, date: Date.current, title: '123', amount: Money.new(123)
  end

  before do
    vendor.update_attribute(:tariff, tariff)
  end

  before :all do
    Sidekiq::Testing.fake!
  end

  before do
    set_current_vendor vendor
  end

  describe '#need_payment' do
    it do
      expect { subject.need_payment(invoice: invoice) }.not_to raise_error
    end
  end

  describe '#not_enough_sms_money' do
    it do
      expect { subject.not_enough_sms_money }.not_to raise_error
    end
  end

  describe '#sms_money_limit_reached' do
    it do
      expect { subject.sms_money_limit_reached }.not_to raise_error
    end
  end

  describe '#unpublish' do
    it do
      expect { subject.unpublish }.not_to raise_error
    end
  end

  describe '#notify_owners' do
    it do
      expect { subject.notify_owners(mail_subject: 'test', mail_text: 'test', sms_text: 'test') }.not_to raise_error
    end
  end

  describe '#balance_refill' do
    it do
      expect { subject.balance_refill(transaction) }.not_to raise_error
    end
  end

  describe '#balance_subtract' do
    it do
      expect { subject.balance_subtract(transaction) }.not_to raise_error
    end
  end
end
