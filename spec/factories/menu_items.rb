# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :menu_item do
    custom_title { 'MyString' }
    place { 'top' }
  end

  factory :menu_item_category, parent: :menu_item, class: 'MenuItemCategory' do
    category { create :category, vendor: vendor }
  end
end
