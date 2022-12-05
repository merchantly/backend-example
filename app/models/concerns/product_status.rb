module ProductStatus
  extend ActiveSupport::Concern

  ARCHIVED_STATUS = :is_archived
  HIDDEN_STATUS = :hidden
  ACTIVE_STATUS = :active

  STATUSES = [ACTIVE_STATUS, HIDDEN_STATUS, ARCHIVED_STATUS].freeze

  included do
    scope :published,        -> { alive.where is_published: true }
    scope :not_published,    -> { alive.where is_published: false }
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

  def is_published
    return true if is_manual_published

    super
  end

  def is_manual_published=(value)
    self.is_published = value
    super
  end

  def is_hidden=(value)
    self.is_published = !value
  end

  def is_hidden
    !is_published?
  end

  def is_active
    is_published?
  end

  def hide!
    update is_manual_published: false
  end

  def active!
    update is_manual_published: true
  end

  alias is_hidden? is_hidden
  alias is_active? is_active
end
