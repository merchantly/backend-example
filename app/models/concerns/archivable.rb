module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archive, -> { where.not(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }
    scope :alive, -> { where archived_at: nil }
  end

  class_methods do
    def archive_all!(at: Time.zone.now)
      update_all archived_at: at
    end
  end

  def active?
    return false if respond_to?(:is_active) && !is_active

    alive?
  end

  def archive
    self.archived_at ||= Time.zone.now
  end

  def archive!
    archive
    save validate: false
  end

  def is_archived=(value)
    if value
      archive unless archived?
    else
      restore if archived?
    end
  end

  def restore
    self.archived_at = nil
  end

  def restore!
    restore
    save validate: false
  end

  def archived?
    archived_at.present?
  end

  def alive?
    archived_at.nil?
  end

  def alive_presence
    alive? ? self : nil
  end

  alias is_archived archived?
end
