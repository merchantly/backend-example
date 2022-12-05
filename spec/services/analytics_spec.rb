require 'rails_helper'

describe Analytics, :vcr do
  subject { described_class.new session: session, cookies: cookies, request: request, vendor: vendor, client: client, title: title }

  let(:path)        { '/some' }
  let(:title)       { 'some title' }
  let(:session)     { OpenStruct.new id: '123' }
  let(:request)     { OpenStruct.new user_agent: '123', remote_ip: '127.0.0.1', path: '/' }

  context 'некому посылать' do
    let(:vendor) { create :vendor }
    let(:client) { nil }
    let(:cookies) { OpenStruct.new signed: {} }

    let(:product) { create :product }

    it do
      expect { subject.view_product(product) }.not_to raise_error
    end
  end

  context 'клиент в convead' do
    let(:app_key) { 'd201374f8837211618a5729d6f489124' }
    let(:vendor) { create :vendor, convead_app_key: app_key }
    let(:client) { nil }
    let(:cookies) { OpenStruct.new 'convead_guest_uid' => 123, 'signed' => {} }

    let(:product) { create :product }

    it do
      expect_any_instance_of(AnalyticsConvead).to receive(:view_product).with(product)
      subject.view_product(product)
    end
  end
end
