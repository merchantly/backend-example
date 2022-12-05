class CommerceML::ExchangeConstraint
  def initialize(type, mode = nil)
    @type = type.to_s
    @mode = mode.to_s
  end

  def matches?(request)
    VendorConstraint.matches?(request) && (type == request.query_parameters['type']) && (mode.blank? || mode == request.query_parameters['mode'])
  end

  private

  attr_reader :type, :mode
end
