class OrderConditionOrder < ApplicationRecord
  belongs_to :order
  belongs_to :order_condition, counter_cache: :used_count
  scope :ordered, -> { order :id }

  after_create do
    order_condition.touch :used_at
  end
end
