class StockImportingLogEntity < ApplicationRecord
  extend Enumerize
  HANGING_PERIOD = MoyskladImporting::VendorLogger::FLUSH_PERIOD + 30.minutes

  STATE_STARTED  = 'started'.freeze
  STATE_FINISHED = 'finished'.freeze
  STATE_ERROR    = 'error'.freeze
  STATE_CANCEL   = 'cancel'.freeze
  STATES = [STATE_STARTED, STATE_FINISHED, STATE_ERROR, STATE_CANCEL].freeze

  belongs_to :vendor
  has_many :records, class_name: 'StockImportingLogEntityRecord', foreign_key: :entity_id, dependent: :delete_all

  scope :last_activity_ago, ->(period) { where 'updated_at<?', period.ago }
  scope :hanged,  -> { started.last_activity_ago HANGING_PERIOD }
  scope :ordered, -> { order 'id desc' }
  scope :started, -> { where state: STATE_STARTED }
  enumerize :state, in: STATES, default: STATE_STARTED

  before_save do
    self.stats ||= {}
  end

  def log
    @log ||= records.order(:id).pluck(:message).join("\n")
  end

  def to_s
    I18n.l created_at, format: :short
  end

  def hanged?
    process? && updated_at < Time.zone.now - HANGING_PERIOD
  end

  def add_log_record(message)
    records.create message: message
  end

  def update_data!(data_values)
    new_data = data.dup
    data_values.each do |k, v|
      k = k.to_s
      new_data[k] ||= 0
      case v
      when '+1'
        new_data[k] = new_data[k].to_i + 1
      when Integer
        new_data[k] = v
      else
        raise "Unknown data type #{v.class}"
      end
    end
    update_attribute :data, new_data
  end

  # Является ли эта попытка синхронизации лишней?
  # Уже есть активная синхронизация?
  def excess?
    vendor.stock_importing_log_entities.where('id<>?', id).started.any?
  end

  def period
    if state == STATE_STARTED
      Time.zone.now - created_at
    else
      updated_at - created_at
    end
  end

  def last_error_message
    records.order(:created_at).last.try(:message)
    # error = log.lines.reverse.find { |l| /\[error\]/=~l } || 'all right'
    # error = error.truncate(200)
    # if error.include?(Moysklad::Client::UnauthorizedError.name)
    # error += I18n.t('bells.Moysklad::Client::UnauthorizedError.text')
    # end
  end

  def finished?
    !process?
  end

  def cancel!
    if finished?
      # SmsWorker.sms_to_support "[#{vendor}/#{id}] Не удачная попытка прервать синх. с moysklad"
      Rails.logger.error "[#{vendor}/#{id}] Не удачная попытка прервать синх. с moysklad"
    else
      # SmsWorker.sms_to_support "[#{vendor}/#{id}] Прерываю синх. с moysklad"
      Rails.logger.error "[#{vendor}/#{id}] Прерываю синх. с moysklad"
      update! state: StockImportingLogEntity::STATE_CANCEL
    end
  end

  def finish!(ok = false)
    update! state: ok ? STATE_FINISHED : STATE_ERROR
    vendor.update_attribute :stock_success_synced_at, Time.zone.now if ok
  end

  def ok?
    state == STATE_FINISHED
  end

  def error?
    state == STATE_ERROR
  end

  def process?
    state == STATE_STARTED
  end

  def process_seconds
    updated_at - created_at
  end

  def stats
    StockImportingStats.new data
  end

  def stats=(value)
    if value.is_a? StockImportingStats
      self.data = value.attributes
    else
      raise 'Must be a StockImportingStats'
    end
  end
end
