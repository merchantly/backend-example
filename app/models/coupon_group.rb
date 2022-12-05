class CouponGroup < Coupon
  MAX_PIECES_COUNT = 20_000

  has_many :coupon_pieces, foreign_key: :group_id

  validates :use_count, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: MAX_PIECES_COUNT }
  validates :discount, presence: true,
                       numericality: { greater_than: 0, less_than_or_equal_to: 100 },
                       if: proc { |coupon| coupon.discount_type.percent? }

  validates :discount, presence: true,
                       numericality: { greater_than: 0 },
                       if: proc { |coupon| coupon.discount_type.fixed? }

  after_update do
    self.class.delay(queue: :critical).sync_pieces(id)
  end

  after_create :generate_pieces

  SYNC_PIECES_FIELDS = %i[
    category_ids
    product_ids
    only_first_order
    archived_at
    discount
    expires_at
    discount_type
    is_check_address
    free_delivery
    minimal_products_count
    use_products_behavior
    use_categories_behavior
  ].freeze

  def used_count
    coupon_pieces.used.count
  end

  def complete?
    uses_count == pieces_count
  end

  def pieces_count
    coupon_pieces.count
  end

  # вызываем через delay
  # купонов может быть много
  def self.sync_pieces(coupon_group_id)
    coupon_group = CouponGroup.find(coupon_group_id)
    coupon_group.coupon_pieces.find_each do |cp|
      cp.update(
        SYNC_PIECES_FIELDS.index_with { |field| coupon_group.send(field) }
      )
    end
  end

  private

  def generate_pieces
    CouponsGenerator.delay.generate id
  end
end
