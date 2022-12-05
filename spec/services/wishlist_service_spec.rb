require 'rails_helper'

RSpec.describe WishlistService, type: :model do
  subject { described_class.find_for_client(vendor: vendor, session: session, client: client) }

  let(:vendor) { create :vendor }
  let(:session) { { described_class::WISHLIST_COOKIE_KEY => slug } }
  let!(:wishlist) { create :wishlist, :with_items, items_count: 2, vendor: vendor }
  let(:slug) { wishlist.slug }
  let(:client) { nil }

  it { expect(subject).to be_a Wishlist }

  context 'после поиска появляется кука' do
    before do
      subject
    end

    it do
      expect(session[described_class::WISHLIST_COOKIE_KEY]).to be_truthy
    end
  end
end
