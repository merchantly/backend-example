require 'rails_helper'

RSpec.describe OrderPaymentW1, type: :model do
  subject { order.order_payment }

  let!(:order) { create :order, :payment_w1 }

  it { expect(subject).to be_persisted }
  it { expect(subject).to be_a described_class }
end
