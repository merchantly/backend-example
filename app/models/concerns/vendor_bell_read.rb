module VendorBellRead
  extend ActiveSupport::Concern

  included do
    scope :fresh, -> { where read_at: nil }
    scope :read, -> { where.not(read_at: nil) }
    scope :unread, -> { fresh }

    scope :by_scope, lambda { |scope|
      case scope.to_sym
      when :all
        all
      when :read
        read
      when :unread
        unread
      else
        raise "Unknown #{state}"
      end
    }
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def read!
    update read_at: Time.zone.now
  end
end
