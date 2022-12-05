require 'rails_helper'

RSpec.describe CouponGroup, type: :model do
  subject { build :coupon_group, use_count: use_count }

  describe 'Нельзя создать группу купонов больше разрешенного количества' do
    let(:use_count) { CouponGroup::MAX_PIECES_COUNT + 1 }

    it do
      expect(subject).to be_invalid
    end
  end
end
