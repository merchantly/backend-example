require 'rails_helper'

RSpec.describe System::RobotsController, type: :controller do
  it do
    get :show
    expect(response).to be_ok
    expect(response.body).to match(/Disallow/)
  end
end
