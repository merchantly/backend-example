# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :invite do
    operator_inviter { create(:operator, :has_vendor) }
    vendor_id { operator_inviter.vendors.first.id }
    sequence :email do |n|
      "email#{n}@email.com"
    end
    sequence :name do |n|
      "invite #{n}"
    end
  end
end
