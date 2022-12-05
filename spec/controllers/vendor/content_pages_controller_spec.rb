require 'rails_helper'

RSpec.describe Vendor::ContentPagesController, type: :controller do
  include VendorControllerSupport

  let!(:content_page) { create :content_page, vendor: vendor }

  before do
    request.path = content_page.public_path
  end

  it do
    get :show, params: { id: content_page.id }
    expect(response).to be_ok
  end
end
