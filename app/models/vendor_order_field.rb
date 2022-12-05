class VendorOrderField < ApplicationRecord
  FIELD_TYPES = %w[string radio].freeze

  extend Enumerize
  include Archivable
  include RankedModel

  belongs_to :vendor, counter_cache: :order_fields_count, touch: true

  scope :ordered, -> { order 'position' }

  ranks :position, with_same: :vendor_id, scope: :alive

  translates :title

  validates :title, presence: true, length: { maximum: 200 }

  validates :list, presence: true, if: :radio?

  enumerize :field_type,
            in: FIELD_TYPES,
            default: FIELD_TYPES.first,
            predicates: true
end
