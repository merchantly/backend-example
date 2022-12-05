require 'rails_helper'

RSpec.describe InviteSends, type: :model do
  let!(:operator) { create :operator, :has_vendor }

  it 'sends email' do
    expect(OperatorMailer).to receive(:new_invite).and_return(FakeMessageDelivery.new)
    create :invite, email: generate(:email), phone: nil
  end

  it 'sends sms' do
    expect(SmsWorker).to receive(:perform_async)
    create :invite, phone: generate(:phone), email: nil, operator_inviter: operator
  end
end
