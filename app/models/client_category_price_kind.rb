class ClientCategoryPriceKind < ApplicationRecord
  belongs_to :price_kind
  belongs_to :client_category

  scope :available, -> { where available: true }
end
