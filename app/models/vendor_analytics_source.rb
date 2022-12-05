class VendorAnalyticsSource < ApplicationRecord
  belongs_to :vendor
  has_many :vendor_analytics_visit_to_sources, dependent: :destroy, foreign_key: :source_id
end
