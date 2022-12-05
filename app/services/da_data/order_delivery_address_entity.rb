class DaData::OrderDeliveryAddressEntity < Grape::Entity
  expose :result, as: :cleanAddress
  expose :postal_code, as: :postalCode
  expose :country
  expose :region
  expose :city
  expose :street
  expose :house
  expose :block
  expose :flat
end
