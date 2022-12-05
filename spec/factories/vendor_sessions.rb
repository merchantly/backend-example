# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_session do
    vendor
    session_id { '123' }
  end
end
