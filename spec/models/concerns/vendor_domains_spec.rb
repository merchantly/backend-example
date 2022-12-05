require 'rails_helper'

RSpec.describe VendorDomains, type: :model do
  context 'by domain' do
    let(:subdomain) { '' }
    let(:env) { { 'HTTP_HOST' => host } }
    let(:request) { ActionDispatch::Request.new env }

    context 'domain' do
      let!(:vendor) { create :vendor, domain: host }

      describe '#tld = 1' do
        let(:host) { 'domain.ru' }

        it { expect(Vendor.find_by_request(request)).to eq vendor }
        it { expect(Vendor.find_by_host(host)).to eq vendor }
      end

      describe '#tld = 2' do
        let(:host) { 'subdomain.domain.ru' }

        it { expect(Vendor.find_by_request(request)).to eq vendor }
        it { expect(Vendor.find_by_host(host)).to eq vendor }
      end
    end

    context 'subdomain' do
      let(:subdomain) { 'subdomain' }
      let(:domain_zone) { 'kiiiosk.com.ua' }
      let(:host) { "#{subdomain}.#{domain_zone}" }
      let!(:vendor) { create :vendor, subdomain: subdomain, domain_zone: domain_zone }

      describe do
        it { expect(Vendor.find_by_request(request)).to eq vendor }
        # it { expect(Vendor.find_by_host(host)).to eq vendor }
      end
    end
  end
end
