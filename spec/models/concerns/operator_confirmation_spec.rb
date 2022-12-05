require 'rails_helper'

RSpec.describe OperatorConfirmation, type: :model do
  let!(:pin_code) { SecureRandom.hex(3) }
  let(:operator) { create :operator }

  describe 'phone confirmation' do
    it 'контролька' do
      expect(operator.phone_confirmed?).to be false
      expect(operator.phone_confirmations).to have(1).items
    end

    context 'phone changed' do
      let!(:operator) { create :operator, phone_confirmed_at: Time.zone.now }
      let!(:new_phone) { generate :phone }

      it 'must reset confirmation and set pin' do
        expect(SmsWorker).to receive(:perform_async)
        operator.update_attribute :phone, new_phone
        expect(operator.phone_confirmed?).to eq false
        expect(operator.phone_confirmations.by_phone(new_phone)).to be_exists
      end
    end

    describe '#confirm_phone!' do
      before { operator.confirm_phone! }

      it 'must confirm phone' do
        expect(operator.phone_confirmed?).to eq true
      end
    end
  end

  describe 'email confirmation' do
    it do
      expect(operator.email_confirmed?).to be false
    end

    context 'email changed' do
      let!(:operator) { create :operator, email_confirmed_at: Time.zone.now }

      it 'must reset confirmation and set pin' do
        # Через сендгрид
        # expect(OperatorMailer).to receive(:email_confirmation).with(operator.id).and_return(FakeMessageDelivery.new)
        operator.update_attribute :email, generate(:email)
        expect(operator.email_confirmed?).to eq false
      end
    end

    describe '#confirm_email!' do
      before { operator.confirm_email! }

      it 'must confirm email' do
        expect(operator.email_confirmed?).to eq true
      end
    end

    context 'если емайл не меняю письмо посылаться не должно' do
      let!(:operator) { create :operator, email: nil }

      it do
        # Через сендгрид
        # expect(OperatorMailer).not_to receive(:email_confirmation)
        operator.update_attribute :name, 'asdsada'
      end
    end
  end
end
