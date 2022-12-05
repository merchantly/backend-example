require 'rails_helper'

RSpec.describe CouponPiece, type: :model do
  let!(:vendor)       { create :vendor }
  let!(:coupon_group) { create :coupon_group, vendor: vendor, discount: 20, use_count: 10, used_count: 0 }
  let!(:coupon_piece) { described_class.create! vendor: vendor, group: coupon_group, discount: 20, use_count: 1 }

  it do
    coupon_piece.call! items_count: 2, is_first_client_order: false, is_address_used: false, total_price: 123

    expect(coupon_piece.used_count).to eq 1
    expect(coupon_piece.use_count).to eq 0
    expect(coupon_group.reload.uses_count).to eq 10
    expect(coupon_group.reload.used_count).to eq 1
    expect(coupon_group.reload.use_count).to eq 9
  end
end
