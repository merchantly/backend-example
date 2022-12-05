module ProductItemSortable
  extend ActiveSupport::Concern

  included do
    include RankedModel

    ranks :position, with_same: :product_id
    scope :ordered_by_product, -> { rank :position }
  end
end
