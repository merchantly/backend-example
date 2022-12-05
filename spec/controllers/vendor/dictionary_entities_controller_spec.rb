require 'rails_helper'

RSpec.describe Vendor::DictionaryEntitiesController, type: :controller do
  include VendorControllerSupport

  let!(:dictionary_entity) { create :dictionary_entity, vendor: vendor }

  before do
    request.path = dictionary_entity.public_path
  end

  it do
    get :show, params: { id: dictionary_entity.id }
    expect(response).to be_ok
  end
end
