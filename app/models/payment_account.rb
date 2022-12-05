class PaymentAccount < ApplicationRecord
  include Authority::Abilities
  include Archivable

  belongs_to :vendor
  has_many :openbill_charges

  scope :by_token, ->(token) { where token: token }
  scope :active, -> { alive.where.not state: 3 }

  scope :ordered, -> { order :card_exp_date }

  enum state: { default: 0, success: 1, retry: 2, fatal: 3 }

  validates :card_first_six, :card_last_four, :card_type, presence: true
  validates :token, uniqueness: { scope: %i[vendor_id] }

  def card
    "#{card_type} #{card_first_six}******#{card_last_four} #{card_exp_date}"
  end

  def to_s
    card
  end

  def inspect
    "#{card} (#{token}) [#{state}]"
  end
end
