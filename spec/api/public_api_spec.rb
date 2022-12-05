require 'rails_helper'

describe PublicAPI, type: :request do
  # before { host! "api.example.com" }
  let!(:vendor)   { create :vendor }

  before          { host! vendor.host }
  #  include Rack::Test::Methods

  it 'ping' do
    get '/api/v1/ping'
    expect(response.status).to eq 200
  end
end
