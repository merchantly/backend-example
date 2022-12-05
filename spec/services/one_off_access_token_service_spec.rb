require 'rails_helper'

describe OneOffAccessTokenService do
  subject { described_class.new }

  let(:value) { '123' }

  specify do
    token = subject.generate value
    expect(subject.find(token)).to eq value
  end
end
