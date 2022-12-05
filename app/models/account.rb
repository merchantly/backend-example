class Account < ApplicationRecord
  belongs_to :vendor
  validates :card_first_six, :card_last_four, :card_type, presence: true

  scope :by_token, ->(token) { where token: token }
end
