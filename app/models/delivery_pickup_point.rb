class DeliveryPickupPoint < ApplicationRecord
  include Archivable
  include Authority::Abilities

  belongs_to :delivery_city
  belongs_to :vendor_delivery

  scope :ordered, -> { order 'address_translations asc' }
  scope :by_address, ->(address) { where "? = ANY(avals(#{arel_table.name}.address_translations))", address }

  counter_culture :delivery_city,
                  column_name: proc { |model| model.alive? ? 'alive_pickup_points_count' : nil },
                  column_names: {
                    'delivery_pickup_points.archived_at is null' => 'alive_pickup_points_count'
                  }

  counter_culture :vendor_delivery,
                  column_name: proc { |model| model.alive? ? 'alive_pickup_points_count' : nil },
                  column_names: {
                    'delivery_pickup_points.archived_at is null' => 'alive_pickup_points_count'
                  }

  translates :address, :details

  validates :address, presence: true, length: { maximum: 200 }
  validates :details, length: { maximum: 200 }

  before_create do
    self.vendor_delivery_id ||= delivery_city.try(:vendor_delivery_id)
  end

  def title
    return address if details.blank?

    "#{address} (#{details})"
  end
end
