require 'rails_helper'

RSpec.describe Invite, type: :model do
  let!(:vendor) { create :vendor }
  let!(:invited) { create :operator }
  let!(:member) { create :member, vendor: vendor, operator: invited }
  let!(:invite) { create :invite, vendor: vendor }

  describe '#accept' do
    it do
      invite.accept! invited
      expect(vendor.reload.operators).to include invited
      expect(invite).to be_destroyed
    end
  end

  describe '#create' do
    context 'w/ unpermitted role' do
      it 'must raise error' do
        expect { create :invite, vendor: vendor, role_id: vendor.roles.owner.id }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'w/ permitted role' do
      let(:invite) { create :invite, role_id: vendor.roles.manager.id }

      it 'must not raise error' do
        expect { invite }.not_to raise_error
      end
    end
  end
end
