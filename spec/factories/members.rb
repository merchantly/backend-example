# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :member do
    vendor
    operator

    after :build do |member|
      member.role = member.vendor.roles.manager if member.role.blank?
    end
  end
end
