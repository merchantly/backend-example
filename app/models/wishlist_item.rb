class WishlistItem < ApplicationRecord
  belongs_to :wishlist, counter_cache: :items_count, touch: true
  belongs_to :product

  has_one :vendor, through: :wishlist

  validates :good_global_id, uniqueness: { scope: :wishlist_id }

  before_create do
    self.product = product_from_good
  end

  def good
    @good ||= vendor.locate_good good_global_id
  end

  def product_from_good
    return if good.blank?

    if good.is_a? ProductItem
      good.product
    else
      good
    end
  end
end
