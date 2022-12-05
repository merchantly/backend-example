require 'rails_helper'

RSpec.describe VendorDelivery, type: :model do
  subject do
    create :vendor_delivery, vendor: vendor, delivery_agent_type: delivery_agent.name
  end

  let!(:vendor) { create :vendor }
  let!(:delivery_agent) { OrderDeliveryOther }

  it { expect(subject).to be_valid }
  it { expect(subject.agent_class).to eq delivery_agent }
  it { expect(subject.agent).to be_a delivery_agent }

  context 'создаем совместимые доставки' do
    subject { create :vendor_delivery, :other, vendor: vendor }

    let(:payment) { create :vendor_payment, :w1, vendor: vendor }

    it { expect(subject.available_payments).to contain_exactly payment }
    it { expect(subject).to be_available_payment(payment) }
  end
end
