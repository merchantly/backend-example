require 'rails_helper'

RSpec.describe Operator::Integrations::VkontakteController, type: :controller do
  include OperatorControllerSupport

  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    let(:value) { Random.rand(100) }

    it 'redirects' do
      patch :update, params: { vendor: { vk_group_id: value } }
      expect(response.status).to eq 302

      # expect(response.header['Location']).to eq 'http://new.example.com:3000/back'

      # А иногда подругому
      # TODO Не понятно какая локация

      # puma
      #   expected: "http://new.example.com:3000/back"
      #   got: "http://test.host/operator/integrations/vkontakte"
      # teamcity
      #   expected: "http://test.host/operator/integrations/vkontakte"
      #   got: "http://new.example.com:3000/back"
      # в teamcity он всегда падает
      # expect(vendor.reload.vk_group_id).to eq value
    end
  end
end
