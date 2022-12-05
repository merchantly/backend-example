module ProductPartOfUnion
  extend ActiveSupport::Concern

  included do
    include RankedModel
    # FIX counter_cache: true как только добавляем счетчик - из
    # ProductUnion пропадает ассоциация items и другие
    belongs_to :product_union

    scope :ordered_by_union, -> { order(union_position: :asc) }

    ranks :union_position, with_same: %i[product_union_id vendor_id]

    after_save :touch_union
    # validate :price_uniqueness
  end

  def is_union
    false
  end

  def is_part_of_union
    product_union_id.present?
  end

  alias is_part_of_union? is_part_of_union

  private

  def touch_union
    product_union.try :touched_product
  end
end
