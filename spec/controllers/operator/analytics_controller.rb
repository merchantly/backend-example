require 'rails_helper'

RSpec.describe Operator::AnalyticsController, type: :controller do
  include OperatorControllerSupport

  let(:product) { create :product, vendor: vendor }

  100.times do
    let!(:analytics_entity) do
      create(
        :analytics_entity,
        vendor: vendor,
        resource: [vendor, product].sample,
        date: Date.current - Random.rand(14).weeks,
        event_type: [
          BaseAnalytics::EVENT_VIEW_PRODUCT,
          BaseAnalytics::EVENT_CREATE_CART,
          BaseAnalytics::EVENT_ADD_TO_CART,
          BaseAnalytics::EVENT_PURCHASE
        ].sample,
        event_count: Random.rand(20)
      )
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end
end
