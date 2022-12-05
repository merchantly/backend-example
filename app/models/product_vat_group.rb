class ProductVatGroup < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor
  has_many :nomenclatures, class_name: 'Ecr::Nomenclature', dependent: :nullify
  has_many :products, through: :nomenclatures

  validates :title, presence: true

  validates :vat, presence: true, uniqueness: { scope: :vendor_id }

  scope :ordered, -> { order :id }

  def product_ids
    return [] if super.blank?

    (super + vendor.products.where(product_union_id: super).pluck(:id)).uniq
  end

  def default?
    vendor.default_product_vat_group == self
  end

  def full_title
    "#{title} (#{vat}%)"
  end
end
