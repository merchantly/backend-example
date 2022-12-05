require 'rails_helper'

describe SystemAPI, type: :request do
  include Rails.application.routes.url_helpers
  #  include Rack::Test::Methods
  before do
    host! 'api.example.com'
  end

  it do
    expect(system_root_url(subdomain: 'api')).to eq api_url
  end

  it 'ping' do
    get '/v1/ping'
    expect(response.status).to eq 200
  end
end
