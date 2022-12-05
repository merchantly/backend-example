FactoryBot.define do
  factory :partner_coupon, class: '::Partner::Coupon' do
    partner
    active_days { 30 }
    sequence :code do |_n|
      SecureRandom.hex(3)
    end
  end
end
