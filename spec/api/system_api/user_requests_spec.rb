require 'rails_helper'

describe SystemAPI::UserRequests do
  let(:params) { { email: 'danil@brandymint.ru', name: '123', phone: '+79033891228' } }

  before do
    host! 'api.example.com'
  end

  it do
    post '/v1/user_requests', params: params

    assert_equal response.status, 201
  end
end
