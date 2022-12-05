require 'rails_helper'

RSpec.describe Vendor::CategoriesController, type: :controller do
  include VendorControllerSupport

  let!(:category) { create :category, vendor: vendor }

  before do
    request.path = category.public_path
  end

  it 'отдается категория по каноническому пути' do
    get :show, params: { id: category.id }
    expect(response).to be_ok
  end
end
