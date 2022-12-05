require 'rails_helper'

RSpec.describe System::MetricsController, type: :controller do
  describe 'GET index' do
    it 'returns http success' do
      get :index, params: { key: Rails.application.secrets.chart_key, subdomain: 'app' }
      expect(response).to be_successful
    end
  end
end
