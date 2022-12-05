# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :wishlist_item do
    wishlist
    good_global_id { create(:product, vendor: wishlist.vendor).global_id }
  end
end
