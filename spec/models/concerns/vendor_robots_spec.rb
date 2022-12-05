require 'rails_helper'

RSpec.describe VendorRobots, type: :model do
  let(:vendor) { create :vendor, domain: 'init.ru' }
  let(:new_host) { 'raki.com' }

  describe '#update_robots_host' do
    context 'domain changed' do
      before { vendor.update_attribute :domain, new_host }

      it { expect(vendor.robots).to match(/Host: http:\/\/#{new_host}/) }
    end

    context 'domain removed' do
      before { vendor.update_attribute :domain, '' }

      it { expect(vendor.robots).to match(/Host: http:\/\/#{vendor.subdomain}\./) }
    end

    context 'empty domain and subdomain changed' do
      let(:vendor) { create :vendor, domain: '' }

      before { vendor.update_attribute :subdomain, 'asdf' }

      it { expect(vendor.reload.robots).to match(/Host: http:\/\/asdf\./) }
    end
  end
end
