require 'rails_helper'

RSpec.describe System::OmniauthSessionsController, type: :controller do
  describe 'GET failure' do
    it 'must render 401' do
      get :failure, params: { subdomain: Settings.app_subdomain }
      expect(response).to render_template :auth_failure
      expect(response.status).to eq(401)
    end
  end
end
