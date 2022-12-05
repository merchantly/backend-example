class Partner::Coupon < ApplicationRecord
  include RoutesConcern
  MAX_LENGTH = 25
  MIN_LENGTH = 3
  FORMAT_MESSAGE = 'Допустимы только символы английского алфавита, цифры, знак минуса и подчеркивание'.freeze

  DEFAULT_ACTIVE_TO = 1.year

  scope :default, -> { where(is_default: true) }

  belongs_to :partner
  has_many :vendors, foreign_key: :partner_coupon_id

  validates :active_days, presence: true, unless: :is_default?

  validates :reward_percent,
            presence: true,
            numericality: { greater_then: 0, less_then: 60 }
  validates :code,
            uniqueness: { case_sensitive: false },
            presence: true,
            length: { maximum: MAX_LENGTH, minimum: MIN_LENGTH },
            format: { with: /\A[a-z0-9\-_]+\z/i, message: FORMAT_MESSAGE }

  before_validation do
    self.active_days = Settings.partner_coupon.active_days if active_days.nil? && !is_default?
  end

  def to_s
    code.upcase
  end

  def transactions
    OpenbillTransaction.where('meta -> \'coupon_code\' = ?', code)
  end

  def registration_url
    system_root_url(
      System::SessionPartnerCoupon::PARAMS_COUPON_CODE => code,
      subdomain: nil # без поддомена красивей
    )
  end

  def perpetual?
    active_days.nil?
  end

  delegate :count, to: :vendors, prefix: true
end
