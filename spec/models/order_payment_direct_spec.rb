require 'rails_helper'

RSpec.describe OrderPaymentDirect, type: :model do
  subject { order.order_payment }

  let!(:order) { create :order, :payment_direct }

  it { expect(subject).to be_persisted }
  it { expect(subject).to be_a described_class }
end
