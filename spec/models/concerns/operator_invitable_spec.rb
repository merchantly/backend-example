require 'rails_helper'

RSpec.describe OperatorInvitable, type: :model do
  subject { build :operator, email: email }

  let!(:vendor)  { create :operator }
  let!(:inviter) { create :operator, :has_vendor }
  let!(:email)   { generate :email }
  let!(:invite)  { create :invite, operator_inviter: inviter, email: email }

  describe '#activate_invites' do
    before { invite }

    context 'guest operator passed' do
      it 'activates invite' do
        expect_any_instance_of(Invite).to receive(:accept!).with(subject)

        subject.send :activate_invites!
      end
    end
  end
end
