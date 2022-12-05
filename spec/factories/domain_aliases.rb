# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :domain_alias do
    vendor
    domain { 'asdf.com' }
  end
end
