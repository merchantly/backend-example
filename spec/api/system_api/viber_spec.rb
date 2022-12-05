require 'rails_helper'

describe SystemAPI::Viber, vcr: true do
  let!(:vendor) { create :vendor, :with_w1_auth, :with_theme, id: 5 }
  let!(:category) { create :category, vendor: vendor }
  let!(:good) { create :product, vendor: vendor, category: category }

  before do
    host! 'api.example.com'
  end

  it do
    post '/v1/viber', params: { format: :json, event: 'webhook' }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'subscribed', sender: { id: '123' } }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'conversation_started', user: { id: '123' } }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'fail', user_id: '123' }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'message', message: { type: 'text', text: "categories-#{vendor.id}" }, sender: { id: '123' } }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'message', message: { type: 'text', text: "goods-#{category.id}" }, sender: { id: '123' } }

    expect(response.status).to eq 201

    post '/v1/viber', params: { format: :json, event: 'message', message: { type: 'text', text: "good-#{good.id}" }, sender: { id: '123' } }

    expect(response.status).to eq 201
  end
end
