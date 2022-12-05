module OperatorControllerSupport
  extend ActiveSupport::Concern
  include CurrentVendor

  included do
    render_views

    let!(:vendor)   { create :vendor }
    let!(:operator) { create :operator }
    let!(:member)   { create :member, operator: operator, vendor: vendor }
    let!(:member)   { create :member, operator: operator, vendor: vendor, role: vendor.roles.owner }

    before do
      allow(controller).to receive(:current_vendor).and_return vendor
      allow(controller).to receive(:current_operator).and_return operator
      allow(controller).to receive(:current_member).and_return member
      @request.env['HTTP_REFERER'] = 'http://new.example.com:3000/back'

      set_current_vendor vendor
    end
  end
end
