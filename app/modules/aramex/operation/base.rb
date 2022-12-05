class Aramex::Operation::Base
  include Virtus.model
  attribute :is_test, Boolean

  protected

  def client
     @client ||= Savon.client(
       wsdl: (is_test ? self.class::TEST_WSDL_HOST : self.class::WSDL_HOST),
       convert_request_keys_to: :none,
       log: true,
       log_level: :debug,
       logger: Aramex.logger,
       pretty_print_xml: true
     )
  end

  def client_info
    @client_info ||= build_client_info
  end

  def build_client_info
    return test_client_info if is_test?

    Aramex::Entity::ClientInfo.new(
      UserName: delivery_type.aramex_username,
      Password: delivery_type.aramex_password,
      Version: delivery_type.aramex_version,
      AccountNumber: delivery_type.aramex_account_number.to_s,
      AccountPin: delivery_type.aramex_account_pin.to_s,
      AccountEntity: delivery_type.aramex_account_entity,
      AccountCountryCode: delivery_type.aramex_account_country_code
    ).to_h
  end

  def test_client_info
    Aramex::Entity::ClientInfo.new(
      UserName: 'testingapi@aramex.com',
      Password: 'R123456789$r',
      Version: 'v1.0',
      AccountNumber: '20016',
      AccountPin: '331421',
      AccountEntity: 'AMM',
      AccountCountryCode: 'JO'
    ).to_h
  end

  def contact(name:, phone:, email:)
    Aramex::Entity::Contact.new(
      Department: '',
      PersonName: name,
      Title: '',
      CompanyName: name,
      PhoneNumber1: phone,
      PhoneNumber1Ext: '',
      PhoneNumber2: '',
      PhoneNumber2Ext: '',
      FaxNumber: '',
      CellPhone: phone,
      EmailAddress: email,
      Type: ''
    ).to_h
  end

  def address(address:, city:, postal_code:, country_code:)
    Aramex::Entity::Address.new(
      Line1: address,
      Line2: '',
      Line3: '',
      City: city,
      StateOrProvinceCode: '',
      PostCode: postal_code,
      CountryCode: country_code
    ).to_h
  end
end
