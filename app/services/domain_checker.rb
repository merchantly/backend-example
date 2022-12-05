class DomainChecker
  def initialize(domain)
    @domain = domain
  end

  def equal_ip?(ip)
    Resolv.getaddress(domain) == ip
  rescue Resolv::ResolvError
    false
  end

  private

  attr_reader :domain
end
