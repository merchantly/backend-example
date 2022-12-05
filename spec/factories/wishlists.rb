# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :wishlist do
    vendor
    client { nil }

    trait :with_items do
      transient do
        items_count { 3 }
      end
      after :create do |wishlist, evaluator|
        wishlist.items << build_list(:wishlist_item, evaluator.items_count, wishlist: wishlist)
      end
    end
  end
end
