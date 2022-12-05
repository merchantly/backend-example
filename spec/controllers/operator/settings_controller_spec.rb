require 'rails_helper'

RSpec.describe Operator::SettingsController, type: :controller do
  include OperatorControllerSupport

  it :index do
    get :index
    expect(response.status).to eq 302
  end

  it :products do
    get :products
    expect(response.status).to eq 200
  end

  it :orders do
    get :orders
    expect(response.status).to eq 200
  end
end
