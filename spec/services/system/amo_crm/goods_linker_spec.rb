require 'rails_helper'

describe System::AmoCRM::GoodsLinker do
  subject { described_class.new(order: order, catalog_id: catalog_id, lead_id: lead_id) }

  before :all do
    stub_request(:post, 'http://test.amocrm.ru.localhost/private/api/auth.php?type=json')
      .to_return(body: { response: { auth: :auth } }.to_json, status: 200)

    stub_request(:get, 'http://test.amocrm.ru.localhost/private/api/v2/json/accounts/current')
                .to_return(body: { response: { auth: :auth } }.to_json, status: 200)
  end

  let(:vendor) { create :vendor, :with_amocrm }
  let(:order)  { create :order, vendor: vendor }

  let(:amocrm_catalog_element_id) { 123 }
  let(:catalog_id) { 456 }
  let(:lead_id) { 987 }

  let(:product) { create :product, amocrm_catalog_element_id: amocrm_catalog_element_id }
  let!(:order_item) { create :order_item, order: order, good: product }

  it 'perform' do
    stub_request(:post, 'http://test.amocrm.ru.localhost/private/api/v2/json/links/set')
      .to_return(body: { response: {} }.to_json, status: 200)

    expect(subject.perform)
  end
end
