# rubocop:disable Style/MixinUsage
include ActiveSupport::Testing::FileFixtures
# rubocop:enable Style/MixinUsage

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
