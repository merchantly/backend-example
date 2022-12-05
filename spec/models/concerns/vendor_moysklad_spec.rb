require 'rails_helper'

RSpec.describe VendorMoysklad, type: :model do
  subject { vendor }

  let!(:vendor) { create :vendor, :moysklad }

  it { expect(vendor.moysklad_password).to be_present }

  describe 'update moysklad_password' do
    context 'empty password' do
      before { vendor.update_attribute :moysklad_password, '' }

      it 'must not update password' do
        expect(vendor.moysklad_password).not_to eq ''
      end
    end

    context 'password present' do
      let(:new_password) { 'pass' }

      before { vendor.update_attribute :moysklad_password, new_password }

      it 'must update password' do
        expect(vendor.moysklad_password).to eq new_password
      end
    end
  end
end
