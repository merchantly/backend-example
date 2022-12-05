require 'rails_helper'

RSpec.describe DomainCleaner, type: :model do
  let(:very_long_subdomain) { 'русские-batoriii-●̃-bloknoty-sketchbuki-wow-such-long-so-muc-h-symbols' }

  it do
    expect(described_class.prepare_subdomain(very_long_subdomain)).to eq 'russkie-batoriii-bloknoty-sketchbuki-wow-such-long-so-muc-'
  end
end
