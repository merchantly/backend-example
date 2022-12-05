require 'rails_helper'

RSpec.describe PhoneConfirmation, type: :model do
  let(:operator)      { create :operator }
  let(:phone)         { '+79033891228' }

  it do
    pc = described_class.new phone: phone, operator: operator
    expect(pc).to receive(:deliver_pin_code!)
    pc.save!
    expect(pc).to be_persisted
  end

  context 'если подтверждается телефон, то он подтверждается и у оператора и в walletone' do
    let(:vendor) { create :vendor }
    let!(:member) { create :member, vendor: vendor, operator: operator }
    let(:phone_confirmation) { create :phone_confirmation, operator: operator, phone: phone }

    before do
      vendor.vendor_walletone.update_columns phone: phone, phone_confirmed_at: nil
    end

    it 'контролька' do
      expect(vendor.vendor_walletone).not_to be_phone_confirmed
    end

    it do
      phone_confirmation.send(:confirm!)
      expect(vendor.vendor_walletone.reload).to be_phone_confirmed
    end
  end
end
