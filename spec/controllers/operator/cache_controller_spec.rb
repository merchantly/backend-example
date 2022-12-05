require 'rails_helper'

RSpec.describe Operator::CacheController, type: :controller do
  include OperatorControllerSupport
  it 'redirects after flush' do
    delete :destroy
    expect(response.status).to eq 302
  end
end
