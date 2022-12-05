require 'rails_helper'

RSpec.describe VendorWorkflowStates, type: :model do
  let!(:vendor) { create :vendor }

  describe 'new идет первым, а failure последним' do
    it do
      expect(vendor.workflow_states.ordered.first.finite_state).to eq :new
      expect(vendor.workflow_states.ordered.last.finite_state).to eq :failure
    end
  end
end
