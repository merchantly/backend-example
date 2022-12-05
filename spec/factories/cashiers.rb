FactoryBot.define do
  factory :cashier, class: 'Ecr::Cashier' do
    vendor

    sequence :name do |n|
      "Cashier-#{n}"
    end
  end
end
