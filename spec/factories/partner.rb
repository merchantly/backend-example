FactoryBot.define do
  factory :partner, class: '::Partner' do
    sequence :name do |n|
      "Партнер #{n}"
    end

    trait :with_coupon do
      after :build do |partner|
        partner.coupons << create(:partner_coupon)
      end
    end
  end
end
