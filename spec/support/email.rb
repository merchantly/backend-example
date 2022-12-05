RSpec.configure do |config|
  # config.include(EmailSpec::Helpers)
  # config.include(EmailSpec::Matchers)

  config.before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  config.after do
    ActionMailer::Base.deliveries.clear
  end
end
