class CouponPiece < CouponSingle
  belongs_to :group,
             class_name: 'CouponGroup',
             counter_cache: :pieces_count

  private

  def on_call
    CouponGroup.update_counters group_id, used_count: 1, use_count: -1
  end
end
