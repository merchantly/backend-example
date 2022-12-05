# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :stock_importing_log_entity_record do
    stock_importing_log_entity { nil }
    message { 'MyText' }
  end
end
