# теги для(на момент создания) товаров
class Tag < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor

  has_many :product_tags, dependent: :destroy
  has_many :products, through: :product_tags

  validates :title, presence: true

  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  translates :title

  validate :title_uniqueness

  def self.create_by_title!(title)
    create! "title_#{I18n.locale}" => title
  end

  def to_s
    title
  end

  # потому что стандартный uniqueness не умеет работать с hstore
  def title_uniqueness
    if vendor.present? && self.class.by_title(title).where(vendor: vendor).where.not(id: id).exists?
      errors.add(:title, '^Такой тег уже существует')
    end
  end
end
