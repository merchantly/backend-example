module OperatorFeatureHelpers
  extend ActiveSupport::Concern

  included do
    before do
      Capybara.app_host = vendor.subdomained_url
      logged_as member
    end
  end
end
