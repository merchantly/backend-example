module AdminControllerSupport
  extend ActiveSupport::Concern
  include Devise::Test::ControllerHelpers

  included do
    render_views

    let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }

    before do
      request.host = 'admin.test.host'
      sign_in admin_user
    end
  end
end
