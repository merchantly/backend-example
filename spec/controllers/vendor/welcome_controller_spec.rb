require 'rails_helper'

RSpec.describe Vendor::WelcomeController, type: :controller do
  include VendorControllerSupport

  let!(:welcome_category) { create :category, vendor: vendor }
  let(:query_object) { controller.send(:query_object) }

  before do
    vendor.update_attribute :welcome_category, welcome_category
  end

  it do
    get :login
    expect(response).to be_redirection
  end

  it do
    expect { get :error }.to raise_error(TestError)
  end

  it 'image/gif' do
    request.env['HTTP_ACCEPT'] = 'image/gif, image/x-xbitmap, image/jpeg,image/pjpeg, application/x-shockwave-flash,application/vnd.ms-excel,application/vnd.ms-powerpoint,application/msword'
    get :index
    expect(response.body).to eq 'only HTML'
  end
end
