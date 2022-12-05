# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :authentication do
    sequence :uid do |n|
      "uid#{n}"
    end

    trait :with_phone do
      sequence :uid do |_n|
        Array.new(11) { rand(1..9).to_s }.join
      end
      provider { 'phone' }
      auth_hash { { 'info' => { 'pin_code' => SecureRandom.hex[1..4] } } }
    end

    authenticatable { create :operator }
  end
end
