# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :role do
    vendor
    sequence :title do |n|
      "role #{n}"
    end
    trait :with_permissions do
      after :create do |role, _opts|
        role.permissions.create! resource_type: 'Product',
                                 can_read: true,
                                 can_update: true,
                                 can_delete: true,
                                 can_create: true
      end
    end
  end
end
