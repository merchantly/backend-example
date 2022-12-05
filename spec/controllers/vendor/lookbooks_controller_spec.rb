require 'rails_helper'

RSpec.describe Vendor::LookbooksController, type: :controller do
  include VendorControllerSupport

  let!(:lookbook) { create :lookbook, vendor: vendor }

  before do
    request.path = lookbook.public_path
  end

  it do
    get :show, params: { id: lookbook.id }
    expect(response).to be_ok
  end
end
