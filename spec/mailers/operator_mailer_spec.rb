require 'rails_helper'

describe OperatorMailer, type: :mailer do
  subject { described_class }

  let(:vendor) { create :vendor }
  let(:member) { create :member, vendor: vendor }
  let(:operator) { member.operator }

  let(:transaction) do
    OpenbillTransaction.create!(
      from_account_id: Billing::SYSTEM_ACCOUNTS[:cloudpayments],
      to_account_id: vendor.common_billing_account.id,
      date: Date.current,
      key: "test_balance_refill:#{Date.current}",
      amount: Money.new(100),
      details: '123',
      meta: {}
    )
  end

  let(:invoice) do
    create :openbill_invoice, destination_account: vendor.common_billing_account, date: Date.current, title: '123', amount: Money.new(123)
  end

  before do
    OpenbillTransaction.delete_all
  end

  it '#negative_balance' do
    expect { subject.negative_balance(member.id, vendor.id, Money.new(-1_00)).deliver }.not_to raise_error
  end

  it '#balance_refill' do
    expect { subject.balance_refill(member.id, vendor.id, transaction.id).deliver }.not_to raise_error
  end

  it '#balance_subtract' do
    expect { subject.balance_subtract(member.id, vendor.id, transaction.id).deliver }.not_to raise_error
  end

  it '#need_payment' do
    expect { subject.need_payment(member.id, vendor.id, invoice.id).deliver }.not_to raise_error
  end

  it '#unpublish' do
    expect { subject.unpublish(member.id, vendor.id).deliver }.not_to raise_error
  end

  it '#not_enough_sms_money' do
    expect { subject.not_enough_sms_money(member.id, vendor.id).deliver }.not_to raise_error
  end

  it '#sms_money_limit_reached' do
    expect { subject.sms_money_limit_reached(member.id, vendor.id).deliver }.not_to raise_error
  end

  it '#notify_member' do
    expect { subject.notify_member(member.id, 'test', 'test').deliver }.not_to raise_error
  end

  context 'invite' do
    let(:invite) { create :invite }

    it '#new_invite' do
      expect { subject.new_invite(invite.id).deliver }.not_to raise_error
    end
  end

  describe '#system_notify' do
    it 'key shop_will_archive' do
      expect { subject.system_notify(operator.id, vendor.id, VendorNotifyMailTemplate::TYPE_SHOP_WILL_ARCHIVE).deliver }.not_to raise_error
    end
  end
end
