class PriceKind < ApplicationRecord
  include Authority::Abilities
  extend Enumerize

  # Тут должны храниться только цены опубликованных товаров
  monetize :min_product_price_cents,
           as: :min_product_price,
           allow_nil: true

  monetize :max_product_price_cents,
           as: :max_product_price,
           allow_nil: true

  before_create do
    self.max_product_price = vendor.zero_money
    self.min_product_price = vendor.zero_money
  end

  validates :title, presence: true

  translates :title

  has_many :product_prices, dependent: :destroy
  belongs_to :vendor

  has_many :client_category_price_kinds, dependent: :destroy
  has_many :client_categories, through: :client_category_price_kinds

  validate :change_default_or_sale_title, if: :will_save_change_to_title_translations?

  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  validate :validate_uniqueness_title, if: :will_save_change_to_title_translations?

  before_destroy do
    vendor.update_column :default_price_kind_id, nil if default?
    vendor.update_column :sale_price_kind_id, nil if sale?
  end

  def reset_min_max_product_prices!
    update(
      min_product_price_cents: product_prices.minimum(:price_cents),
      min_product_price_currency: vendor.default_currency,
      max_product_price_cents: product_prices.maximum(:price_cents),
      max_product_price_currency: vendor.default_currency
    )
  end

  def is_default_or_sale?
    default? or sale?
  end

  def custom?
    !is_default_or_sale?
  end

  def default?
    vendor.default_price_kind_id == id
  end

  def sale?
    vendor.sale_price_kind_id == id
  end

  def display_name
    title
  end

  private

  def change_default_or_sale_title
    return if new_record?

    errors.add :title, 'Нельзя изменять имя у дефолтной цены или цены распродажи' if is_default_or_sale?
  end

  def validate_uniqueness_title
    title_values = title.is_a?(Hash) ? title.values : [title]

    title_values.each do |title_value|
      errors.add :title_translations, I18n.t('errors.price_kind.not_unique_title') if PriceKind.by_title(title_value).exists?(vendor: vendor)
    end
  end
end
