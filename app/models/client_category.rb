class ClientCategory < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor

  scope :for_client_select, ->(vendor) { where.not(id: vendor.anonymous_client_category_id) }

  has_many :available_client_category_price_kinds, -> { available }, class_name: 'ClientCategoryPriceKind'
  has_many :price_kinds, through: :available_client_category_price_kinds

  has_many :clients, dependent: :nullify

  has_many :client_category_price_kinds, dependent: :destroy
  accepts_nested_attributes_for :client_category_price_kinds

  translates :title

  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  before_destroy do
    vendor.update_column :anonymous_client_category_id, nil if default?
    vendor.update_column :default_client_category_id, nil if anonymous?
  end

  def custom?
    !default? && !anonymous?
  end

  def default?
    vendor.anonymous_client_category_id == id
  end

  def anonymous?
    vendor.default_client_category_id == id
  end

  def available_price_kinds
    return vendor.price_kinds if all_prices_available?

    price_kinds
  end
end
