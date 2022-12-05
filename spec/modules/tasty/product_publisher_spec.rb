require 'rails_helper'

describe Tasty::ProductPublisher, vcr: true do
  subject { described_class.new(product: product, tasty_user_token: token) }

  let(:product) { create :product }
  let(:token) { 'valid_token' }

  context 'valid token' do
    it 'must return entry id' do
      expect(subject.call).to eq 20_740_652
    end
  end

  context 'invalid token' do
    let(:token) { 'invalid_token' }

    it 'must raise error' do
      VCR.use_cassette :tasty do
        expect { subject.call }.to raise_error(Tasty::ProductPublisher::Error)
      end
    end
  end
end
