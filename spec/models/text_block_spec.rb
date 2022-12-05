require 'rails_helper'

RSpec.describe TextBlock, type: :model do
  subject { create :text_block }

  it { expect(subject).to be_persisted }
end
