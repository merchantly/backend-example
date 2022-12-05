require 'rails_helper'

RSpec.describe OrderPaymentPayPal, type: :model do
  subject { order.order_payment }

  let!(:order) { create :order, :payment_pay_pal }

  it { expect(subject).to be_persisted }
  it { expect(subject).to be_a described_class }
end
