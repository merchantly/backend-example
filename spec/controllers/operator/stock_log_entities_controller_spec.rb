require 'rails_helper'

RSpec.describe Operator::StockLogEntitiesController, type: :controller do
  include OperatorControllerSupport

  let(:log_entity) { create :stock_importing_log_entity, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show, params: { id: log_entity.id }
      expect(response.status).to eq 200
    end
  end
end
