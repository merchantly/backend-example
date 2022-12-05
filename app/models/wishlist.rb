class Wishlist < ApplicationRecord
  belongs_to :vendor
  belongs_to :client
  has_many :items, class_name: 'WishlistItem'
  has_many :products, through: :items

  before_create :set_slug

  def to_param
    slug
  end

  delegate :count, to: :items, prefix: true

  def has_product?(product)
    items.find { |i| i.product == product }.present?
  end

  def has_items?
    items.exists?
  end

  def goods
    items.map(&:good)
  end

  def add_item(good_id)
    good = vendor.locate_good good_id
    items.find_or_create_by! good_global_id: good.global_id
  end

  def remove_item(good_id)
    item = items.find_by(good_global_id: good_id)
    return if item.blank?

    item.destroy!
  end

  private

  def set_slug
    self.slug = SecureRandom.hex(16)
  end
end
