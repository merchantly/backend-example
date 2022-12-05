require 'rails_helper'

RSpec.describe Vendor::CartPackagesController, type: :controller do
  include VendorControllerSupport

  let!(:package) { create :product, vendor: vendor, category_ids: [vendor.package_category.id] }

  it 'create' do
    post :create, params: { package_good_global_id: package.global_id, id: 'any' }
    expect(response).to be_redirection
  end

  it 'update' do
    delete :destroy, params: { id: 'any' }
    expect(response).to be_redirection
  end
end
