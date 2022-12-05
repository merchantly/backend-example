class Session < ActiveRecord::SessionStore::Session
  has_one :cart, primary_key: :session_id, dependent: :destroy

  # {init: true}
  # "BAh7BjoJaW5pdFQ=\n"
  #
  scope :empty_data, -> { where data: serialize({}) }

  def self.purge(_id)
    find_by(id: id).try :purge
  end

  def purge
    return if wishlist.present? && (wishlist.items_count.positive? || wishlist.items.any?)
    return if cart.present? && (cart.items_count.positive? || cart.items.any?)

    destroy
  end

  def wishlist
    wishlist_slug = data.with_indifferent_access[WishlistService::WISHLIST_COOKIE_KEY]
    return if wishlist_slug.blank?

    @wishlist ||= Wishlist.find_by_slug(wishlist_slug)
  end
end
