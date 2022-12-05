require 'rails_helper'

RSpec.describe Client, type: :model do
  let(:client) { create :client }

  it do
    expect(client).to be_persisted
  end
end
