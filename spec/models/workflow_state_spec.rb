require 'rails_helper'

RSpec.describe WorkflowState, type: :model do
  subject { create :workflow_state }

  it do
    expect(subject).to be_persisted
  end
end
