# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :history_path do
    path { '/aaa' }
    vendor
    controller_name { 'products' }
    action_name { 'show' }
  end
end
