require 'rails_helper'

describe SmsCountCalculator do
  subject do
    described_class.new(phones: phones, message: message)
  end

  describe '#call' do
    context '1 phone' do
      let(:phones) { ['+79111111111'] }
      let(:message) { 'test' }

      it do
        expect(subject.call).to eq 1
      end
    end

    context '2 phone' do
      let(:phones) { ['+79111111111', '+79111111112'] }
      let(:message) { 'test' }

      it do
        expect(subject.call).to eq 2
      end
    end

    context 'long message' do
      let(:phones) { ['+79111111111'] }
      let(:message) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.' }

      it do
        expect(subject.call).to eq 2
      end
    end
  end
end
