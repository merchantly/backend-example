class Aramex::Entity::ClientInfo
  include Virtus.model

  attribute :UserName, String
  attribute :Password, String
  attribute :Version, String
  attribute :AccountNumber, String
  attribute :AccountPin, String
  attribute :AccountEntity, String
  attribute :AccountCountryCode, String
end
