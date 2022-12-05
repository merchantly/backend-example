require 'rails_helper'

RSpec.describe BranchCategory, type: :model do
  subject { create :branch_category }

  it do
    expect(subject).to be_persisted
  end
end
