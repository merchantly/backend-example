# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  sequence(:slug_path) { |n| "/path#{n}" }
  factory :slug do
    path { generate :slug_path }
    vendor
  end

  factory :slug_resource, class: 'SlugResource', parent: :slug do
    resource { create :product, vendor: vendor }
  end

  factory :slug_redirect, class: 'SlugRedirect', parent: :slug do
    resource { create :category, vendor: vendor }
    redirect_path { resource.public_path }
  end
end
