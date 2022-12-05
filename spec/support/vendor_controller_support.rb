module VendorControllerSupport
  extend ActiveSupport::Concern
  include CurrentVendor

  included do
    render_views
    let!(:vendor)   { create :vendor, :with_theme, :with_package_category, :payments_and_deliveries }
    let!(:operator) { create :operator }
    let!(:member)   { create :member, operator: operator, vendor: vendor }

    before do
      request.host = vendor.host
      allow(controller).to receive(:current_vendor).and_return vendor
      allow(controller).to receive(:current_operator).and_return operator
      allow(controller).to receive(:current_member).and_return member

      set_current_vendor vendor
    end
  end
end
