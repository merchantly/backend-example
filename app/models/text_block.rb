class TextBlock < ApplicationRecord
  include RankedModel
  include Authority::Abilities

  belongs_to :vendor
  belongs_to :product, inverse_of: :text_blocks
  belongs_to :vendor

  has_one :linked_text_block, class_name: 'TextBlock'

  scope :ordered, -> { rank :position }

  scope :with_current_locale, -> { where("coalesce((title_translations -> '#{I18n.locale}'::TEXT), (content_translations -> '#{I18n.locale}'::TEXT), '') <> ''") }

  # Выдываем до ranks
  ranks :position, with_same: :product_id

  validates :title,   presence: true
  validates :content, presence: true

  translates :title, :content

  def title_to_use
    title.presence || linked_text_block.try(:title)
  end

  def content_to_use
    content.presence || linked_text_block.try(:content)
  end
end
