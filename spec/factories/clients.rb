# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :client do
    vendor
    name { 'MyString' }

    before(:create) do |client, _evaluator|
      client.emails << build_list(:client_email, 1, client: client)
      client.phones << build_list(:client_phone, 1, client: client)
    end

    trait :with_orders do
      after :create do |client, _evaluator|
        client.orders << create(:order, :items, client: client, vendor: client.vendor)
      end
    end
  end
end
