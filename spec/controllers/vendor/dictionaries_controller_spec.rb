require 'rails_helper'

RSpec.describe Vendor::DictionariesController, type: :controller do
  include VendorControllerSupport

  let!(:dictionary) { create :dictionary, vendor: vendor }

  before do
    request.path = dictionary.public_path
  end

  it do
    get :show, params: { id: dictionary.id }
    expect(response).to be_ok
  end
end
