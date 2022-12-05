require 'rails_helper'

describe OperatorAPI, type: :request do
  include OperatorRequests
  let!(:vendor) { create :vendor, :with_w1_auth, :with_theme }

  #  include Rack::Test::Methods
  it 'ping' do
    get '/operator/api/v1/ping'
    expect(response.status).to eq 200
  end

  it 'whoami' do
    get '/operator/api/v1/whoami'
    expect(response.status).to eq 200
  end
end
