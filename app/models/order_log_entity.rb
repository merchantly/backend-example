class OrderLogEntity < ApplicationRecord
  belongs_to :order
  belongs_to :author, class_name: 'Operator'

  validates :message, presence: true

  serialize :dump

  scope :ordered, -> { order 'id desc' }

  # Мимикрируем под AdminComment
  def body
    message
  end
end
