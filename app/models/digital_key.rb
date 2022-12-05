class DigitalKey < ApplicationRecord
  include WorkflowActiverecord

  STATE_NO_USED = 'no_used'.freeze
  STATE_USED = 'used'.freeze

  belongs_to :product
  has_one :order_item, dependent: :nullify

  scope :active, -> { where used: STATE_NO_USED }

  validates :key, presence: true, uniqueness: { scope: :product_id }

  workflow_column :used

  workflow do
    state STATE_NO_USED do
      event :use, transitions_to: STATE_USED
    end
    state STATE_USED
    on_transition do |from, to, _triggering_event, *_event_args|
      if (from == STATE_NO_USED) && (to == STATE_USED)
        order_item.update digital_key_string: key
      end
    end
  end
end
