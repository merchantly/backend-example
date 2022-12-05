require 'rails_helper'

RSpec.describe ContentPageImage, type: :model do
  subject { create :content_page_image }

  it { expect(subject).to be_valid }
  it { expect(subject).to be_a described_class }
end
