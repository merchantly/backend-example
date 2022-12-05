class Aramex::Entity::TrackerResponse
  include Virtus.model

  attribute :update_code, String
  attribute :update_description, String
  attribute :update_date_time, String
  attribute :update_location, String

  def self.dump(obj)
    obj.to_hash
  end

  def self.load(obj)
    new(obj)
  end
end
