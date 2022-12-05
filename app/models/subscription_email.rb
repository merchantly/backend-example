class SubscriptionEmail < ApplicationRecord
  include Authority::Abilities
  belongs_to :vendor

  has_one :client_email, foreign_key: :email, primary_key: :email
  has_one :client, through: :client_email

  validates :email, presence: true
  validates :email, email: true

  scope :with_client, -> { includes(:client) }
  scope :ordered,     -> { order 'id desc' }
end
