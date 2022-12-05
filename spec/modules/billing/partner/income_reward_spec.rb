require 'rails_helper'

RSpec.describe Billing::Partner::IncomeReward do
  subject do
    described_class.new(transaction: transaction, vendor: vendor)
  end

  let(:operator) { create :opreator }
  let(:partner) { create :partner, operator: operator }
  let(:partner_coupon) { create :partner_coupon }
  let!(:vendor) { create :vendor, partner_coupon_code: partner_coupon.code }
  let(:transaction) { double id: SecureRandom.uuid, amount: Money.new(123) }

  it do
    expect_any_instance_of(described_class).to receive(:make_transaction).and_call_original
    expect { subject.call }.not_to raise_error
  end
end
