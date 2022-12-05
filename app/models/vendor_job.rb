class VendorJob < ApplicationRecord
  extend Enumerize
  STATES = { created: 0, process: 1, success: 2, failure: 3, cancel: 4 }.freeze
  TYPES  = { ymls: 'VendorJobYML', vkontakte: 'VendorJobVkontakte' }.freeze

  belongs_to :vendor

  mount_uploader :asset, FileUploader
  serialize :parameters

  scope :ordered, -> { order id: :desc }
  scope :ymls,    -> { where type: 'VendorJobYML' }
  scope :filtered, ->(filter) { where type: TYPES[filter] }
  scope :process, -> { where state: STATES[:process] }

  enumerize :state, in: STATES, default: 0, scope: true, predicates: true

  before_save do
    raise 'Can`t be VendorJob. Use STI' if instance_of?(VendorJob)
  end

  after_commit :enqueue, on: :create

  def self.restart_zombies
    VendorJob.with_state(:process).find_each(&:restart)
  end

  def to_s
    "#{title}: #{progress}% (#{total}/#{current}) (#{result})"
  end

  def restart
    if process? && !working?
      perform_async
    end
  end

  def speed
    t = updated_at - created_at
    return if t.zero? || current < 10

    (3600 * current / t).to_i
  end

  def left_time
    return unless process?

    t = updated_at - created_at
    return if t.zero? || current < 10

    total * t / current.to_f
  end

  def working?
    Sidekiq::Status.working? sidekiq_job_id
  end

  def perform!
    update state: :process
    run
    finish!
  rescue SystemExit, Interrupt
    binding.debug_error
    cancel!
  rescue StandardError => e
    finish! e.message, false
    binding.debug_error
    raise e if Rails.env.development?

    Bugsnag.notify e, metaData: { vendor_job_id: id }
  end

  def update_inspector!
    update progress: inspector.progress, total: inspector.total, current: inspector.current, result: inspector.details
  end

  def cancel!
    update_attribute :state, :cancel
  end

  def finish!(result = '', is_success = true)
    attrs = {}
    if is_success
      attrs[:progress] = 100
      attrs[:state] = :success
    else
      attrs[:progress] = 0 if progress.nil?
      attrs[:state] = :failure
    end
    attrs[:result] = result if result.present?
    update attrs
  end

  private

  def sidekiq_worker_class
    VendorJobWorker
  end

  def enqueue
    update_column(:sidekiq_job_id, perform_async) if sidekiq_job_id.blank?
  end

  def perform_async
    sidekiq_worker_class.perform_async id
  end

  def inspector
    @inspector ||= JobInspector::VendorJobInspector.new self
  end

  def file
    asset.try(:file).try(:file)
  end
end
