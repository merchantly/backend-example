require 'rails_helper'

RSpec.describe ReactPropsHelper do
  FakeController = Class.new do
    def self.helper_method(*_args); end
    include ReactPropsHelper
    def current_vendor; end

    def request; end
  end

  subject do
    fake_controller.send(:switch_locales)
  end

  let(:fake_controller) { FakeController.new }

  let(:vendor) { create :vendor, available_locales: %i[ru en] }
  let(:path) { '' }
  let(:base_url) { 'https://shop.com' }
  # let(:req)          { ActionDispatch::TestRequest.new env }
  let(:req) { double path: path, query_parameters: {}, base_url: base_url }

  before do
    Thread.current[:vendor] = vendor

    allow(fake_controller).to receive(:current_vendor).and_return(vendor)
    allow(fake_controller).to receive(:request).and_return(req)
  end

  context 'главная' do
    let(:resource) { nil }

    context 'default' do
      let(:path) { '/' }

      it do
        expect(subject).to eq [{ lang: 'ru', url: base_url }, { lang: 'en', url: "#{base_url}/en" }]
      end
    end

    context 'english' do
      let(:path) { '/en' }

      it do
        expect(subject).to eq [{ lang: 'ru', url: base_url }, { lang: 'en', url: "#{base_url}/en" }]
      end
    end
  end

  context 'ресурс без языка' do
    let(:path) { '/products/123-test' }

    it do
      expect(subject).to eq [{ lang: 'ru', url: "#{base_url}/products/123-test" }, { lang: 'en', url: "#{base_url}/en/products/123-test" }]
    end
  end

  context 'ресурс с языком' do
    let(:path) { '/en/products/123-test' }

    it do
      expect(subject).to eq [{ lang: 'ru', url: "#{base_url}/products/123-test" }, { lang: 'en', url: "#{base_url}/en/products/123-test" }]
    end
  end
end
