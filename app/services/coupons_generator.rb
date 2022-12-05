class CouponsGenerator
  def self.generate(coupon_group_id)
    new(CouponGroup.find(coupon_group_id)).generate!
  end

  def initialize(coupon_group)
    @coupon_group = coupon_group
  end

  def generate!
    coupon_group.use_count.times.each do
      create_coupon
    end
  end

  private

  attr_reader :coupon_group

  MAX_TRIES = 5

  def create_coupon
    tries = 1
    begin
      CouponPiece.create!(
        CouponGroup::SYNC_PIECES_FIELDS.index_with { |field| coupon_group.send(field) }.merge(
          use_count: 1,
          group: coupon_group,
          vendor: coupon_group.vendor
        )
      )
    rescue ActiveRecord::RecordInvalid => e
      if tries < MAX_TRIES
        tries += 1
        retry
      else
        raise e
      end
    end
  end
end
