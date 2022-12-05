class VendorRobotsEditor
  include Virtus.model
  USER_AGENT_DEFAULT = "User-agent: *\n".freeze
  DEFAULT = USER_AGENT_DEFAULT

  attribute :vendor, Vendor
  attribute :robots, String, default: ->(form, _attr) { form.vendor.robots.to_s }

  HOST_PATTERN = /^.*Host:.*$/.freeze
  USER_AGENT_PATTERN = /User-agent:/.freeze
  SITEMAP_PATTERN = /^.*Sitemap:.*$/.freeze
  COMMENT_PATTERN = /^#.*/.freeze
  DISALLOW_PATTERN = /Disallow:\s*\/\s*$/.freeze
  DISALLOW_ORDERS_PATTERN = /Disallow:\s*\/orders\/*\s*$/.freeze
  DISALLOW_CART_PATTERN = /Disallow:\s*\/cart\/*\s*$/.freeze
  DISALLOW_WISHLIST_PATTERN = /Disallow:\s*\/wishlist\/\**\s*$/.freeze

  # TODO add disallow
  # Disallow: *utm_
  # Disallow: *per_page
  # Disallow: *currency_iso_code
  # Disallow: *slug_path

  def set_defaults
    append_user_agent unless has_user_agent?
    remove_host
    append_host
    add_orders_disallow unless orders_disallowed?
    add_cart_disallow unless cart_disallowed?
    add_wishlist_disallow unless wishlist_disallowed?
    append_sitemap unless has_sitemap?
    remove_empty_lines
    save
  end

  def reset
    self.robots = DEFAULT.dup
    set_defaults
  end

  def update_host
    remove_host
    append_host
    remove_empty_lines
    save
  end

  def update_sitemap
    remove_sitemap
    append_sitemap
    remove_empty_lines
    save
  end

  private

  def remove_empty_lines
    robots.squeeze!("\n")
  end

  def has_host?
    robots_without_comments.match HOST_PATTERN
  end

  def has_user_agent?
    robots_without_comments.match USER_AGENT_PATTERN
  end

  def has_sitemap?
    robots_without_comments.match SITEMAP_PATTERN
  end

  def orders_disallowed?
    robots_without_comments.match DISALLOW_ORDERS_PATTERN
  end

  def cart_disallowed?
    robots_without_comments.match DISALLOW_CART_PATTERN
  end

  def wishlist_disallowed?
    robots_without_comments.match DISALLOW_WISHLIST_PATTERN
  end

  def append_user_agent
    robots.prepend USER_AGENT_DEFAULT
  end

  def append_host
    robots.prepend "Host: #{vendor.public_url}\n"
  end

  def remove_host
    robots.gsub! HOST_PATTERN, ''
  end

  def append_sitemap
    robots.prepend "Sitemap: #{vendor.sitemap_url}\n"
  end

  def remove_sitemap
    robots.gsub! SITEMAP_PATTERN, ''
  end

  def add_orders_disallow
    robots << "\nDisallow: /orders"
  end

  def add_cart_disallow
    robots << "\nDisallow: /cart"
  end

  def add_wishlist_disallow
    robots << "\nDisallow: /wishlist/*"
  end

  def save
    VendorRobotsResource.new(vendor: vendor).save robots
  end

  def robots_without_comments
    robots.gsub COMMENT_PATTERN, ''
  end
end
