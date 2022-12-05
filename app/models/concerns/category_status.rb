module CategoryStatus
  extend ActiveSupport::Concern

  ARCHIVED_STATUS = :is_archived
  HIDDEN_STATUS = :hidden
  ACTIVE_STATUS = :active

  STATUSES = [ACTIVE_STATUS, HIDDEN_STATUS, ARCHIVED_STATUS].freeze

  included do
    scope :published, -> { alive.where is_published: true }
    scope :hidden,    -> { alive.where is_published: false }
  end

  def is_hidden
    !is_published?
  end

  def is_active
    is_published?
  end

  def status
    if archived?
      ARCHIVED_STATUS
    elsif is_hidden?
      HIDDEN_STATUS
    else
      ACTIVE_STATUS
    end
  end

  def hide!
    update is_published: false

    products.map(&:hide!)
  end

  def active!
    update is_published: true

    products.map(&:active!)
  end

  alias is_hidden? is_hidden
  alias is_active? is_active
end
