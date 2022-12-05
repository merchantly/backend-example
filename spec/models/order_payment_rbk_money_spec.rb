require 'rails_helper'

RSpec.describe OrderPaymentRbkMoney, type: :model do
  subject { order.order_payment }

  let!(:order) { create :order, :payment_rbk_money }

  it { expect(subject).to be_persisted }
  it { expect(subject).to be_a described_class }
end
