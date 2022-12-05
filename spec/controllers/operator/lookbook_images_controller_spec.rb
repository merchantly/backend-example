require 'rails_helper'

RSpec.describe Operator::LookbookImagesController, type: :controller do
  include OperatorControllerSupport

  let(:lookbook) { create :lookbook, vendor: vendor }
  let(:lookbook_image) { create :lookbook_image, lookbook: lookbook }
  let(:image) { fixture_file_upload('donut_1.png', 'image/png') }
  let(:image_attributes) { build(:lookbook_image, vendor: vendor, lookbook: lookbook).attributes.merge!(image: image) }

  describe 'POST create' do
    it 'redirects' do
      post :create, params: { lookbook_id: lookbook.id, lookbook_image: image_attributes }
      expect(response.status).to eq 200
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      delete :destroy, params: { lookbook_id: lookbook.id, id: lookbook_image.id }
      expect(response.status).to eq 302
    end
  end
end
