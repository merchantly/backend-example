module CommerceML
  extend AutoLogger

  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end
end

CommerceMl = CommerceML
