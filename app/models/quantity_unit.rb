class QuantityUnit < ApplicationRecord
  extend Enumerize
  include Authority::Abilities

  NotDestroyedError = Class.new StandardError

  has_many :nomenclatures, class_name: 'Ecr::Nomenclature'
  belongs_to :vendor

  DIVISIBLE_TYPE = 'divisible'.freeze
  INDIVISIBLE_TYPE = 'indivisible'.freeze
  TYPES = [DIVISIBLE_TYPE, INDIVISIBLE_TYPE].freeze

  CUSTOM_KEY = :custom

  enumerize :unit_type, in: TYPES, default: INDIVISIBLE_TYPE

  validates :title, :short, :key, presence: true
  validates :unit_type, presence: true, inclusion: { in: TYPES }

  translates :title, :short

  scope :ordered, -> { order id: :asc }

  before_save do
    self.key ||= CUSTOM_KEY
  end

  before_destroy do
    raise NotDestroyedError, I18n.t('errors.quantity_unit.not_destroyed_with_nomenclatures') if nomenclatures.exists?
  end

  def to_s
    title
  end

  def is_default?
    VendorQuantityUnits::DEFAULT_KEYS.include? key.to_sym
  end
end
