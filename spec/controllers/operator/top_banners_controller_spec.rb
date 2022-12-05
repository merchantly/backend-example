require 'rails_helper'

RSpec.describe Operator::TopBannersController, type: :controller do
  include OperatorControllerSupport

  let(:top_banner) { create :top_banner, vendor: vendor }

  describe 'GET show' do
    it 'redirects' do
      get :show
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    let(:top_banner) { build :top_banner, vendor: vendor }

    it 'redirects' do
      expect_any_instance_of(TopBanner).to receive :update!
      post :create, params: { top_banner: top_banner.attributes, theme: { banner_visible: false } }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(TopBanner).to receive :update!
      patch :update, params: { id: top_banner.id, top_banner: { content: 'asdf' }, theme: { banner_visible: false } }
      expect(response.status).to eq 302
    end
  end
end
