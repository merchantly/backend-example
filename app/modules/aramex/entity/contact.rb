class Aramex::Entity::Contact
  include Virtus.model

  attribute :Department, String
  attribute :PersonName, String
  attribute :Title, String
  attribute :CompanyName, String
  attribute :PhoneNumber1, String
  attribute :PhoneNumber1Ext, String
  attribute :PhoneNumber2, String
  attribute :PhoneNumber2Ext, String
  attribute :FaxNumber, String
  attribute :CellPhone, String
  attribute :EmailAddress, String
  attribute :Type, String
end
