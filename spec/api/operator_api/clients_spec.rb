require 'rails_helper'

describe OperatorAPI::Categories do
  include OperatorRequests

  describe 'POST /clients' do
    it 'create client with exists phone' do
      params = {
        name: 'Example name one',
        phones: ['+79677777777'],
        emails: ['example1@gmail.com']
      }

      post '/operator/api/v1/clients', params: params

      expect(response.status).to eq 201

      params = {
        name: 'Example name two',
        phones: ['+79677777777'],
        emails: ['example2@gmail.com']
      }

      post '/operator/api/v1/clients', params: params

      expect(response.status).to eq 422
    end
  end
end
