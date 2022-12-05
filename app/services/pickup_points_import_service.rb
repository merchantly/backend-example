class PickupPointsImportService < BaseImportService
  def initialize(delivery)
    @delivery = delivery
    super delivery.vendor
  end

  def perform(file:, skip_headers: true)
    archive_not_synced delivery.pickup_points do
      super file: file, skip_headers: skip_headers do |row|
        address = row[1].to_s.strip.chomp
        city = find_or_create_city(row[0].to_s.strip.chomp)
        details = row[2].to_s.strip.chomp

        pp = delivery.pickup_points.by_address(address).where(delivery_city: city).take

        pp = delivery.pickup_points.build address: address, delivery_city: city if pp.blank?

        pp.assign_attributes details: details, updated_at: sync_at, archived_at: nil
        pp.save!

        synced_ids << pp.id
      end
    end
  end

  private

  attr_reader :delivery, :sync_at, :synced_ids

  def archive_not_synced(scope)
    @synced_ids = []
    @sync_at = Time.zone.now

    yield

    scope.where.not(id: synced_ids).archive_all!
    delivery.pickup_points.counter_culture_fix_counts
  end

  def find_or_create_city(city_title)
    city = delivery.delivery_cities.by_title(city_title).take
    return delivery.delivery_cities.create!(title: city_title) if city.blank?

    city.restore! unless city.alive?

    city
  end
end
