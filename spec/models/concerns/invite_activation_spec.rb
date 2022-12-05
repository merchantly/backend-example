require 'rails_helper'

RSpec.describe InviteActivation, type: :model do
  let(:vendor) { create :vendor }
  let(:guest) { create :operator }

  describe '#find_and_bind_operators' do
    subject { Invite.new email: guest.email, vendor: vendor }

    it do
      expect(subject.find_and_bind_operators).to include(guest)
    end
  end
end
