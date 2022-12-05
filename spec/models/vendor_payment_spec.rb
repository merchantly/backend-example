require 'rails_helper'

RSpec.describe VendorPayment, type: :model do
  subject do
    create :vendor_payment, vendor: vendor, payment_agent_type: payment_agent.name
  end

  let!(:vendor) { create :vendor }
  let!(:payment_agent) { OrderPaymentDirect }

  it { expect(subject).to be_valid }
  it { expect(subject.agent_class).to eq payment_agent }
  it { expect(subject.agent).to be_a payment_agent }
  it { expect(subject.available_deliveries).to eq [] }

  context 'создаем совместимые доставки' do
    let!(:vendor_delivery) { create :vendor_delivery, :other, vendor: vendor }

    it { expect(subject.available_deliveries).to contain_exactly vendor_delivery }
  end
end
