module VendorClientWishlistSupport
  def client_add_wishlist_url
    "#{home_url}/wishlist/items"
  end

  def client_wishlist_url
    "#{home_url}/wishlist"
  end
end
