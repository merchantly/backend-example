require 'rails_helper'

RSpec.describe System::WelcomeController, type: :controller do
  describe 'GET index' do
    it 'returns http redirect' do
      request.host = 'app.test.host'
      get :index
      expect(response.status).to eq 302
    end
  end

  describe 'GET job' do
    it 'returns http success' do
      get :job
      expect(response.status).to eq 200
    end
  end
end
