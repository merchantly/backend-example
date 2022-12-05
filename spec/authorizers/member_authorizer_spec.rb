require 'rails_helper'

RSpec.describe MemberAuthorizer do
  subject(:self_member) { described_class.new(current_member) }

  let(:vendor) { create :vendor }
  let!(:role_owner) { vendor.roles.owner }
  let!(:role_manager) { vendor.roles.manager }
  let!(:role_guest) { vendor.roles.guest }
  let!(:operator)  { build :operator }
  let!(:operator2) { build :operator }
  let(:member)     { build :member, operator: operator2, vendor: vendor }

  let(:other_member) { described_class.new(member) }

  describe '#deletable_by?' do
    context 'owner' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role: role_owner }

      it 'deletes himself' do
        expect(self_member.deletable_by?(current_member)).to eq false
      end

      context 'deletes owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it { expect(other_member.deletable_by?(current_member)).to eq true }
      end

      context 'deletes manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it { expect(other_member.deletable_by?(current_member)).to eq true }
      end

      context 'deletes guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it { expect(other_member.deletable_by?(current_member)).to eq true }
      end
    end

    context 'manager' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role: role_manager }

      it 'deletes himself' do
        expect(self_member.deletable_by?(current_member)).to eq false
      end

      context 'deletes owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it { expect(other_member.deletable_by?(current_member)).to eq false }
      end

      context 'deletes manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it { expect(other_member.deletable_by?(current_member)).to eq true }
      end

      context 'deletes guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it { expect(other_member.deletable_by?(current_member)).to eq true }
      end
    end

    context 'guest' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role: role_guest }

      it 'deletes himself' do
        expect(self_member.deletable_by?(current_member)).to eq false
      end

      context 'deletes owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it { expect(other_member.deletable_by?(current_member)).to eq false }
      end

      context 'deletes manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it { expect(other_member.deletable_by?(current_member)).to eq false }
      end

      context 'deletes guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it { expect(other_member.deletable_by?(current_member)).to eq false }
      end
    end
  end

  describe '#updatable_by?' do
    context 'owner' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role: role_owner }

      it 'updates himself' do
        expect(self_member.updatable_by?(current_member)).to eq true
        expect(self_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
      end

      context 'updates owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it do
          expect(other_member.updatable_by?(current_member)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq true
        end
      end

      context 'updates manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it do
          expect(other_member.updatable_by?(current_member)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq true
        end
      end

      context 'updates guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it do
          expect(other_member.updatable_by?(current_member)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq true
        end
      end
    end

    context 'manager' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role_id: role_manager.id }

      it 'updates himself' do
        expect(self_member.updatable_by?(current_member)).to eq true
        expect(self_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
      end

      context 'updates owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it do
          expect(other_member.updatable_by?(current_member)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        end
      end

      context 'updates manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it do
          expect(other_member.updatable_by?(current_member)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq true
        end
      end

      context 'updates guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it do
          expect(other_member.updatable_by?(current_member)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq true
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq true
        end
      end
    end

    context 'guest' do
      let(:current_member) { build :member, operator: operator, vendor: vendor, role: role_guest }

      it 'updates himself' do
        expect(self_member.updatable_by?(current_member)).to eq true
        expect(self_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
        expect(self_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
      end

      context 'updates owner' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_owner }

        it do
          expect(other_member.updatable_by?(current_member)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        end
      end

      context 'updates manager' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_manager }

        it do
          expect(other_member.updatable_by?(current_member)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        end
      end

      context 'updates guest' do
        let(:member) { build :member, operator: operator2, vendor: vendor, role: role_guest }

        it do
          expect(other_member.updatable_by?(current_member)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_owner.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_manager.id)).to eq false
          expect(other_member.updatable_by?(current_member, role_id: role_guest.id)).to eq false
        end
      end
    end
  end
end
