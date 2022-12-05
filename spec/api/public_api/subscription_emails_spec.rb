require 'rails_helper'

describe PublicAPI::SubscriptionEmails do
  let(:params) { { email: 'test@test.ru' } }
  let!(:vendor) { create :vendor }

  before { host! vendor.host }

  it do
    post '/api/v1/subscription_emails', params: params

    assert_equal response.status, 201
  end
end
