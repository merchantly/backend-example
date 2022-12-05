require 'rails_helper'

RSpec.describe Operator::AnalyticsDaysController, type: :controller do
  include OperatorControllerSupport

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end
