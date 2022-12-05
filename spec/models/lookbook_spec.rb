require 'rails_helper'

RSpec.describe Lookbook, type: :model do
  subject! { create :lookbook }

  it { expect(subject).to be_a described_class }
  it { expect(subject.mandatory_image).to be_a BaseUploader }
end
