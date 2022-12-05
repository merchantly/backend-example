class ClientAuthTypeChecker
  def self.perform!(vendor:, login_form:)
    checker = new(vendor: vendor, login_form: login_form)

    checker.perform!
  end

  def initialize(vendor:, login_form:)
    @vendor = vendor
    @login_form = login_form
  end

  def perform!
    auth_type = vendor.client_authorization_type.to_sym

    return if auth_type == :by_email_or_phone

    if (auth_type == :by_phone && !login_form.phone?) || (auth_type == :by_email && !login_form.email?)
      raise ClientAuthTypeError.new(auth_type)
    end
  end

  private

  attr_reader :vendor, :login_form

  class ClientAuthTypeError < StandardError
    attr_reader :auth_type

    def initialize(auth_type)
      @auth_type = auth_type
    end

    def message
      case auth_type
      when :by_phone
        I18n.vt('flashes.client.auth_type.only_by_phone')
      when :by_email
        I18n.vt('flashes.client.auth_type.only_by_email')
      else
        raise "Unknown #{auth_type}"
      end
    end
  end
end
