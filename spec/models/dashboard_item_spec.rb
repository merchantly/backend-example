require 'rails_helper'

RSpec.describe DashboardItem, type: :model do
  subject { build :dashboard_item, key: 'example_key', icon: 'pay', title: 'example_title', text: 'example_text', position: 1 }

  it 'Проверяем на корректность' do
    expect(subject).to be_valid
  end
end
