class DeliveryCity < ApplicationRecord
  include Archivable
  include Authority::Abilities

  belongs_to :delivery, class_name: 'VendorDelivery'
  has_many :pickup_points, class_name: 'DeliveryPickupPoint', dependent: :delete_all

  counter_culture :delivery,
                  column_name: proc { |model| model.alive? ? 'alive_cities_count' : nil },
                  column_names: {
                    'delivery_cities.archived_at is null' => 'alive_cities_count'
                  }

  scope :ordered,          -> { order 'title_translations asc' }
  scope :by_title,         ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  # reverse_geocoded_by :latitude, :longitude

  translates :title

  validates :title, presence: true, length: { maximum: 200 }

  def to_s
    title
  end
end
