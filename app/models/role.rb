class Role < ApplicationRecord
  include Authority::Abilities

  OWNER = :owner
  MANAGER = :manager
  GUEST = :guest
  SELLER = :seller
  CASHIER = :cashier
  CUSTOM = :custom

  include DefaultRolePermissions

  DEFAULT_ROLES = [OWNER, MANAGER, GUEST].freeze
  ECR_DEFAULT_ROLES = [SELLER, CASHIER].freeze
  DEFAULT_ROLE = MANAGER

  belongs_to :vendor
  has_many :permissions, class_name: 'RolePermission', dependent: :destroy
  has_many :members, dependent: :restrict_with_error

  accepts_nested_attributes_for :permissions, reject_if: :all_blank

  validates :key, presence: true
  validates :permissions, presence: true, if: :custom?

  validate :no_duplicate_permissions
  validate :validate_title

  translates :title

  scope :ordered, -> { order :id }
  scope :without_owner, -> { where.not(key: OWNER) }

  before_validation :set_key
  before_destroy :check_default_role

  delegate :count, to: :members, prefix: true

  before_validation do
    self.key ||= CUSTOM
  end

  def self.owner
    find_by key: OWNER
  end

  def self.manager
    find_by key: MANAGER
  end

  def self.manager!
    manager || create!(key: MANAGER, title_translations: HstoreTranslate.translations(MANAGER, %i[enumerize member role]))
  end

  def self.guest
    find_by key: GUEST
  end

  def self.guest!
    guest || create!(key: GUEST, title_translations: HstoreTranslate.translations(GUEST, %i[enumerize member role]))
  end

  def owner?
    key.to_sym == OWNER
  end

  def guest?
    key.to_sym == GUEST
  end

  def manager?
    key.to_sym == MANAGER
  end

  def custom?
    key.to_sym == CUSTOM
  end

  private

  def check_default_role
    if DEFAULT_ROLES.include?(key.to_sym)
      errors.add :base, 'Запрещено удалять базовые роли'
      return false
    end

    true
  end

  def set_key
    self.key = title.parameterize if key.blank? && title.present?
  end

  def validate_title
    title_values = title_translations.values

    errors.add(:title, 'not empty') unless title_values.any?(&:present?)
    errors.add(:title, I18n.t('errors.name_validator')) unless title_values.map { |value| value.blank? || TitleValidator::TITLE_REGEXP.match(value).present? }.reduce(:&)
  end

  def no_duplicate_permissions
    errors.add(:permissions, 'have duplicate') if permissions.group_by(&:resource_type).values.detect { |arr| arr.size > 1 }
  end
end
