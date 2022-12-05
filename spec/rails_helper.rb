# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'spec_helper'
require 'rspec/rails'
require 'capybara-screenshot/rspec'
require 'capybara/email/rspec'
require 'capybara/rspec'
require 'rack_session_access/capybara'
require 'email_spec'
# require "email_spec/rspec"
require 'sidekiq/testing'
require 'vcr'
require 'sidekiq_unique_jobs/testing'

require 'test_prof/recipes/rspec/let_it_be'
require 'test_prof/recipes/rspec/before_all'
# require 'capybara/poltergeist'
# Capybara.javascript_driver = :poltergeist

# * http://viget.com/extend/auto-saving-screenshots-on-test-failures-other-capybara-tricks
# * http://macbury.ninja/2014/12/rspec-take-screenshoot-on-capybara-test-failure
# * https://gist.github.com/mattheworiordan/1156691
#
# Saves screenshots into ./tmp/capybara
Capybara::Screenshot.autosave_on_failure = true
# Capybara.save_and_open_page_path = "/file/path"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# WebMock.disable_net_connect!(allow: 'codeclimate.com')

ActiveJob::Base.queue_adapter = :test

# https://github.com/rails/rails/pull/285#issuecomment-2482862
require 'bcrypt'
silence_warnings do
  BCrypt::Engine::DEFAULT_COST = BCrypt::Engine::MIN_COST
end

Aws.config.update(stub_responses: true)

connection = ActiveRecord::Base.connection
res = connection.execute("select count(*) from pg_trigger where tgname like '%openbill%';")
raise "В базе (#{connection.current_database}) нет openbill триггеров, попробуйте RAILS_ENV=test rails db:reset_openbill_triggers" unless res[0]['count'] == 2

RSpec.shared_context 'sidekiq:inline', sidekiq: :inline do
  around do |ex|
    Sidekiq::Testing.inline!(&ex)
  end
end

# TestProf.configure do |config|
## the directory to put artifacts (reports) in ("tmp/test_prof" by default)
# config.output_dir = 'tmp/test_prof'

## use unique filenames for reports (by simply appending current timestamp)
# config.timestamps = true

## color output
# config.color = true
# end

RSpec.configure do |config|
  config.include_context 'sidekiq:inline', include_shared: true
  VCR.configure do |c|
    c.configure_rspec_metadata!
    # Можно устанавливать прямов feature через vcr: { record: :new_episodes }
    c.default_cassette_options = { record: :new_episodes }
    # c.default_cassette_options = { :record => :once }

    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock
    c.ignore_hosts 'codeclimate.com'
    c.ignore_hosts 'notify.bugsnag.com'
    c.allow_http_connections_when_no_cassette = false

    # c.ignore_hosts 'kiiiosk-test.s3.eu-central-1.amazonaws.com'
    # c.ignore_hosts '127.0.0.1', 'localhost'
    # c.ignore_localhost = false
    # c.debug_logger = $stderr
  end

  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: /spec\/api/
  config.include FeatureHelpers, type: :feature
  config.include CapybaraHiddenFields, type: :feature

  config.include NumericHelper
  config.include MoneyHelper, type: :feature
  config.include MoneyRails::ActionViewExtension, type: :feature

  config.include ViewSpecHelper, type: :view
  config.include ViewSpecHelper, type: :helper
  config.include DescribedViewSupport, type: :view
  # config.include(ViewSpecHelper, type: :controller)
  # config.before(:each, type: :controller) { initialize_view_helpers(controller) }
  config.before(:each, type: :controller) { request.tld_length = 1 }

  config.include ProcessWithRequestSubdomain, type: :controller

  config.before(:all, type: :feature) { ActiveJob::Base.queue_adapter = :inline }
  config.after(:all, type: :feature) { ActiveJob::Base.queue_adapter = :test }

  config.before(:all, type: :model) { ActiveJob::Base.queue_adapter = :test }
  config.before(:all, type: :commands) { ActiveJob::Base.queue_adapter = :test }
  config.before(:all, type: :controller) { ActiveJob::Base.queue_adapter = :test }

  config.before(:each, type: :helper) { initialize_view_helpers(helper) }
  config.before(:each, type: :view) { initialize_view_helpers(view) }
  config.after(:each, type: :controller) { Gon.clear }

  config.include OperatorFeatureHelpers, file_path: /spec\/features\/operator/
  config.include OperatorViewSupport, file_path: /spec\/views\/operator/
  config.include AdminControllerSupport, file_path: /spec\/controllers\/admin/
  config.before :each, type: :controller, file_path: /spec\/controllers\/system/ do
    request.host = 'app.test.host'
  end

  config.before(:suite) do
    load Rails.root.join('db/seeds.rb')
  end

  # sql logging
  # ActiveRecord::Base.logger = Logger.new(STDOUT) if defined?(ActiveRecord::Base)

  # config.before do
  #   stub_request(:any, /#{Regexp.quote(URI.parse(W1::API_URL).host)}/).to_rack(W1ApiMock.new)
  # end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.file_fixture_path = Rails.root.join('spec/fixtures')
  config.fixture_path = Rails.root.join('spec/fixtures')

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.fail_fast = false

  unless ENV['USER'] =~ /teamcity/ || ENV['NO_FOCUS']
    config.profile_examples = 10
    config.filter_run focus: true
  end

  config.run_all_when_everything_filtered = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!
  # config.include RSpec::Rails::RequestExampleGroup, type: :request, example_group: {
  # file_path: /spec\/api/
  # }
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(SmsMock)
  config.include(GoogleSpreadsheetMock)
  config.before do
    Sidekiq::Worker.clear_all
    stub_sms
  end

  config.after(:all) do
    if Rails.env.test?
      FileUtils.rm_rf(Dir[Rails.root.join('/spec/support/uploads')])
    end
  end
end
