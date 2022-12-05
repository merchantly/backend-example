class VendorAnalyticsVisitorEvent < ApplicationRecord
  belongs_to :vendor
  belongs_to :visitor

  belongs_to :resource, polymorphic: true
  belongs_to :product

  enum event: { visit: 0 }
end
