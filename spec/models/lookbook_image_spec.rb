require 'rails_helper'

RSpec.describe LookbookImage, type: :model do
  subject { create :lookbook_image }

  it { expect(subject).to be_a described_class }

  it do
    expect(subject.image).to receive(:adjusted_url)

    subject.adjusted_url
  end
end
