class Aramex::Operation::RateCalculator < Aramex::Operation::Base
  WSDL_HOST = 'https://ws.aramex.net/ShippingAPI.V2/RateCalculator/Service_1_0.svc?singleWsdl'.freeze
  TEST_WSDL_HOST = 'https://ws.dev.aramex.net/ShippingAPI.V2/RateCalculator/Service_1_0.svc?singleWsdl'.freeze

  def perform
    res = calculate_rate.body

    raise if res[:rate_calculator_response][:has_errors]
  end

  private

  def calculate_rate
    client.call(:calculate_rate, message: data)
  end

  def data
    {
      ClientInfo: test_client_info,
      Transaction: Aramex::Entity::Transaction.new(Reference1: '1', Reference2: '', Reference3: '', Reference4: '', Reference5: '').to_h,
      OriginAddress: Aramex::Entity::Address.new(Line1: 'mittova 7', Line2: '', Line3: '', City: 'cheboksary', StateOrProvinceCode: '123', PostCode: '428000', CountryCode: 'RU').to_h,
      DestinationAddress: Aramex::Entity::Address.new(Line1: 'mittova 8', Line2: '', Line3: '', City: 'cheboksary', StateOrProvinceCode: '123', PostCode: '428000', CountryCode: 'RU').to_h,
      ShipmentDetails: details
    }
  end
end
