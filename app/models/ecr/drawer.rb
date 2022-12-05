class Ecr::Drawer < ApplicationRecord
  include Authority::Abilities
  include WorkflowActiverecord

  OPEN_STATE = 'opened'.freeze
  CLOSE_STATE = 'closed'.freeze
  STATES = [OPEN_STATE, CLOSE_STATE].freeze

  workflow_column :state

  workflow do
    state OPEN_STATE do
      event :close, transitions_to: CLOSE_STATE
    end
    state CLOSE_STATE
  end

  self.table_name = :ecr_drawers

  belongs_to :vendor
  belongs_to :cashier, class_name: 'Ecr::Cashier'

  belongs_to :open_operator, class_name: 'Operator'
  belongs_to :close_operator, class_name: 'Operator'

  belongs_to :open_correct_document, class_name: 'Ecr::CorrectDocument'
  belongs_to :close_correct_document, class_name: 'Ecr::CorrectDocument'

  validates :state, inclusion: { in: STATES }
  validates :opened_at, :open_balance, :open_actual_balance, presence: true
  validates :close_actual_balance, numericality: { less_than: ApplicationRecord::MAX_INTEGER, greater_than_or_equal_to: 0 }, presence: true, if: :closed_at

  validate :check_exist_other_open_drawers
  validate :validate_opened_at

  scope :ordered, -> { order opened_at: :desc }
  scope :by_any_document_id, ->(id) { where('open_correct_document_id = ? or close_correct_document_id = ? ', id, id) }

  scope :by_date, ->(date) { where('DATE(opened_at AT TIME ZONE ?) = ?', Time.zone.formatted_offset, date) }
  scope :by_state, ->(state) { where(state: state) }

  monetize :open_balance_cents
  monetize :open_actual_balance_cents

  monetize :close_balance_cents, allow_nil: true
  monetize :close_actual_balance_cents, allow_nil: true

  monetize :sale_amount_cents, allow_nil: true
  monetize :refund_amount_cents, allow_nil: true

  monetize :open_correct_amount_cents, allow_nil: true
  monetize :close_correct_amount_cents, allow_nil: true

  monetize :close_net_balance_cents, allow_nil: true

  before_validation on: :create do
    self.open_balance = calculate_current_balance
    self.open_correct_amount = open_actual_balance - open_balance
    self.number = generate_number
  end

  after_save do
    if open_correct_document.blank? && open_correct_amount != Money.zero
      form = Ecr::DocumentForm::Correct.new(
        vendor: vendor,
        cashier_id: cashier.id,
        amount: open_correct_amount
      )

      document = Ecr::DocumentRegistrar.correct(form)

      update_column :open_correct_document_id, document.id
    end

    if close_correct_document.blank? && close_correct_amount.to_money != Money.zero
      form = Ecr::DocumentForm::Correct.new(
        vendor: vendor,
        cashier_id: cashier.id,
        amount: close_correct_amount
      )

      document = Ecr::DocumentRegistrar.correct(form)

      update_column :close_correct_document_id, document.id
    end
  end

  def calculate_current_balance
    calculator.total_amount(nil, opened_at)
  end

  def calculate_sale_amount
    calculator.sale_amount(opened_at, closed_at + 1.minute)
  end

  def calculate_refund_amount
    calculator.refund_amount(opened_at, closed_at + 1.minute)
  end

  def calculate_close_balance
    calculator.total_amount(nil, closed_at + 1.minute)
  end

  private

  def close(form)
    self.close_operator_id = form.close_operator_id
    self.close_actual_balance = form.close_actual_balance
    self.description = form.description
    self.closed_at = form.closed_at

    self.sale_amount = calculate_sale_amount
    self.refund_amount = calculate_refund_amount
    self.close_balance = calculate_close_balance

    self.close_correct_amount = close_actual_balance - close_balance
    self.close_net_balance = close_actual_balance - open_actual_balance

    save!
  end

  def calculator
    Ecr::CashierAmountCalculator.new cashier: cashier
  end

  def check_exist_other_open_drawers
    errors.add(:cashier, I18n.t('errors.drawer.open_drawer_exist')) if closed_at.blank? && cashier.open_drawer.present?
  end

  def validate_opened_at
    if closed_at.blank? && cashier.drawers.exists?(['closed_at >= ?', opened_at])
      errors.add(:opened_at, I18n.t('errors.drawer.opened_at'))
    end
  end

  def generate_number
    cashier.drawers.by_date(opened_at.to_date).where('opened_at < ?', opened_at).count + 1
  end
end
