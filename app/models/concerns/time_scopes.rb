module TimeScopes
  extend ActiveSupport::Concern

  included do
    scope :in_days,           ->(days)  { where 'created_at>=?', Time.zone.now - days.days }
    scope :in_hours,          ->(hours) { where 'created_at>=?', Time.zone.now - hours.hours if hours.present? }
    scope :by_date,           lambda { |date|
      where 'created_at>=? and created_at<=?',
            date.beginning_of_day,
            date.end_of_day
    }

    scope :updated_by_day, lambda { |date|
      where 'orders.updated_at>? and orders.updated_at<=?',
            date.yesterday,
            date
    }

    scope :by_day,            lambda { |date|
      where 'created_at>? and created_at<=?',
            date.yesterday,
            date
    }

    scope :recent, ->(count) { ordered.limit(count) }
  end
end
