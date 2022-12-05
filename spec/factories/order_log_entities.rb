# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order_log_entity do
    order { nil }
    message { 'MyText' }
  end
end
