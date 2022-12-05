require 'rails_helper'

RSpec.describe Partner::Coupon, type: :model do
  subject { build :partner_coupon, code: 'ABC-123_17' }

  it { expect(subject).to be_valid }
end
