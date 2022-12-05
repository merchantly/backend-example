require 'rails_helper'

RSpec.describe Operator::BellsController, type: :controller do
  include OperatorControllerSupport

  describe 'GET read_all' do
    it 'redirects' do
      get :read_all
      expect(response.status).to eq 302
    end
  end
end
