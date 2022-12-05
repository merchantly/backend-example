class DigitalKeysImport < ApplicationRecord
  include WorkflowActiverecord

  STATE_FRESH = 'fresh'.freeze
  STATE_PENDING = 'pending'.freeze
  STATE_ERROR = 'error'.freeze
  STATE_SUCCESS = 'success'.freeze

  belongs_to :product

  mount_uploader :digital_keys_file, DigitalKeysFileUploader

  delegate :vendor_id, :vendor, to: :product

  workflow_column :state

  workflow do
    state STATE_FRESH do
      event :pending, transitions_to: STATE_PENDING
      event :error, transitions_to: STATE_ERROR
    end

    state STATE_PENDING do
      event :success, transitions_to: STATE_SUCCESS
      event :error, transitions_to: STATE_ERROR
    end
    state STATE_ERROR
    state STATE_SUCCESS
  end

  def fail_error!(error)
    update error_message: error
    error!
  end
end
