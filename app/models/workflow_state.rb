class WorkflowState < ApplicationRecord
  extend Enumerize
  include Authority::Abilities
  include Archivable
  include RankedModel
  include ColorHex

  FINITE_STATES = %i[new in_process success failure].freeze

  enumerize :finite_state, in: FINITE_STATES, predicates: true, scope: true

  scope :ordered, -> { order :position }
  scope :by_name, ->(name) { where "? = ANY(avals(#{arel_table.name}.name_translations))", name }

  belongs_to :vendor
  has_many :orders

  ranks :position, with_same: :vendor_id, scope: :alive

  validates :name, presence: true

  validate :validate_uniqueness_name, if: :will_save_change_to_name_translations?

  translates :name

  validate :new_once
  validate :required

  before_create :setup_convead_key

  def self.default
    with_finite_state(:new).first
  end

  def self.failure
    with_finite_state(:failure).first
  end

  def finish?
    success? || failure?
  end

  def working?
    !finish?
  end

  def to_s
    title
  end

  def to_label
    to_s
  end

  def title
    name
  end

  def required
    required_state :success
    required_state :failure
  end

  def required_state(state)
    scope = vendor.workflow_states.with_finite_state(state)
    return if scope.count > 1
    return unless scope.include? self

    unless finite_state == state.to_s
      errors.add :finite_state, I18n.t('errors.workflow_state.remove_only_final_state')
    end
  end

  def new_once
    if vendor.workflow_states.default == self
      unless finite_state.new?
        errors.add :finite_state, I18n.t('errors.workflow_state.remove_new_state')
      end
    else
      if finite_state.new? && persisted?
        errors.add :finite_state, I18n.t('errors.workflow_state.set_new_state')
      end
    end
  end

  private

  # Соответские киосковских значений конвидовским
  # https://monosnap.com/file/K3VK2cTn3nFyxbyR2ZTvbh8tZNiLEV
  #
  CONVEAD_KEYS = {
    new: :new,
    success: :shipped,
    failure: :canceled
  }.freeze

  def setup_convead_key
    self.convead_key ||= CONVEAD_KEYS[finite_state.to_sym]
  end

  def validate_uniqueness_name
    name_values = name.is_a?(Hash) ? name.values : [name]

    name_values.each do |name_value|
      ws_ids = WorkflowState.by_name(name_value).where(vendor: vendor).pluck(:id)

      errors.add :name_translations, I18n.t('errors.workflow_state.not_unique_name') if ws_ids.present? && ws_ids.exclude?(id)
    end
  end
end
