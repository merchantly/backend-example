require 'rails_helper'

describe SystemAPI::Vendors do
  let(:demo_vendor) { create :vendor, :payments_and_deliveries }
  let!(:vendor_template) { create :vendor_template, vendor: demo_vendor }
  let(:operator) { create :operator }

  let(:params) { { name: 'Store name', uuid: SecureRandom.uuid } }

  before do
    host! 'api.example.com'
    vendor_template.precreate!
    $operator = operator
  end

  it do
    post '/v1/vendors', params: params

    expect(response.status).to eq 201

    post '/v1/vendors', params: params

    expect(response.status).to eq 200
    expect(operator.available_vendors.count).to eq 1
  end
end
