class WishlistService
  WISHLIST_COOKIE_KEY = :kiosk_wishlist_key

  def self.find_for_client(vendor:, session:, client: nil)
    new(vendor: vendor, session: session, client: client)
      .find_for_client
  end

  def initialize(vendor:, session:, client: nil)
    @vendor  = vendor
    @session = session
    @client  = client
  end

  def find_for_client
    wishlist = vendor.wishlists.find_or_create_by(slug: wishlist_slug)
    set_wishlist_slug wishlist.slug
    wishlist
  end

  private

  attr_reader :vendor, :session, :client

  def wishlist_slug
    session[WISHLIST_COOKIE_KEY]
  end

  def set_wishlist_slug(slug)
    session[WISHLIST_COOKIE_KEY] = slug
  end
end
