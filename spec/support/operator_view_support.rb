module OperatorViewSupport
  extend ActiveSupport::Concern
  included do
    let!(:vendor)   { create :vendor }
    let!(:operator) { create :operator }
    let!(:member)   { create :member, operator: operator, vendor: vendor }

    before do
      allow(view).to receive(:current_vendor).and_return vendor
      allow(view).to receive(:current_operator).and_return operator
      allow(view).to receive(:current_member).and_return member
      view.lookup_context.prefixes << 'operator/base'
    end
  end
end
