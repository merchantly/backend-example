# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order_stock do
    order { nil }
    ms_order_uuid { 'MyString' }
    ms_order_dump { 'MyText' }
    reserved_at { '2015-09-20 09:24:59' }
    unreserved_at { '2015-09-20 09:24:59' }
    is_reserved { false }
    reservation_result { 'MyString' }
    unreservation_result { 'MyString' }
  end
end
