module Sortable
  extend ActiveSupport::Concern

  included do
    include RankedModel

    # важно менять позицию только среди живых сущностей
    # иначе при изминении сортировки будут учитываться мертвые товары
    ranks :position, with_same: :vendor_id, scope: :alive
    scope :ordered, -> { rank :position }
  end
end
