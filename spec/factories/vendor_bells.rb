# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :vendor_bell do
    vendor { '' }
    key { 'MyString' }
    options { '' }
    read_at { '2015-04-07 16:34:38' }
  end
end
