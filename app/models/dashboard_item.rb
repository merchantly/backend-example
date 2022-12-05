class DashboardItem < ApplicationRecord
  DEFAULT_ITEMS = {
    design: 'paint-brush',
    main: 'cart-plus',
    pay: 'usd',
    del: 'truck',
    pages: 'file-text',
    help: 'question',
  }.freeze

  translates :title, :text

  scope :ordered, -> { order 'position asc' }

  validates :key, :title, :text, :position, presence: true

  def to_param
    key
  end

  def to_s
    title
  end

  def self.create_defaults!
    return if DashboardItem.exists?

    DEFAULT_ITEMS.each_with_index do |arr, i|
      key, icon = arr

      DashboardItem.create!(
        key: key,
        icon: icon,
        title_translations: HstoreTranslate.translations(:title, [:operator, :dashboard, key]),
        text_translations: HstoreTranslate.translations(:body, [:operator, :dashboard, key]),
        position: i
      )
    end
  end
end
