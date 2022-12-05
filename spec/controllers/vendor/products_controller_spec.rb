require 'rails_helper'

RSpec.describe Vendor::ProductsController, type: :controller do
  include VendorControllerSupport

  let!(:product) { create :product, vendor: vendor }

  # Возможно это лучше вынести в тест SluggagleResource
  it 'редирект на канонический url' do
    get :show, params: { id: product.id }
    expect(response).to be_redirection
    expect(response.redirect_url).to eq product.public_url
  end

  it 'отдается товар по каноническому пути' do
    request.path = product.public_path
    get :show, params: { id: product.id }
    expect(response).to be_ok
  end
end
