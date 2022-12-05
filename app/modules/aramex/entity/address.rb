class Aramex::Entity::Address
  include Virtus.model

  attribute :Line1, String
  attribute :Line2, String
  attribute :Line3, String
  attribute :City, String
  attribute :StateOrProvinceCode, String
  attribute :PostCode, String
  attribute :CountryCode, String
end
