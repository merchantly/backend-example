require 'rails_helper'

RSpec.describe Operator::ContentPageImagesController, type: :controller do
  include OperatorControllerSupport

  let(:content_page) { create :content_page, vendor: vendor }
  let(:content_page_image) { create :content_page_image, content_page: content_page }
  let(:image) { fixture_file_upload('donut_1.png', 'image/png') }
  let(:image_attributes) { build(:content_page_image, vendor: vendor, content_page: content_page).attributes.merge!(image: image) }

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { content_page_id: content_page.id, content_page_image: image_attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      delete :destroy, params: { content_page_id: content_page.id, id: content_page_image.id }
      expect(response.status).to eq 302
    end
  end
end
