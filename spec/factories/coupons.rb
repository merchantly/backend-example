# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :coupon do
    vendor
    use_count { 10 }
    used_count { 1 }
    discount { 20 }
    only_first_order { false }
    is_discounting_package { false }

    trait :expired do
      use_count { 0 }
      archived_at { 1.day.ago }
    end
  end

  factory :coupon_free_delivery, parent: :coupon, class: 'CouponSingle' do
    free_delivery { true }
  end

  factory :coupon_single, parent: :coupon, class: 'CouponSingle'

  factory :coupon_piece, parent: :coupon_single, class: 'CouponPiece' do
    group
  end

  factory :coupon_group, parent: :coupon, class: 'CouponGroup' do
    use_count { 10 }
  end
end
