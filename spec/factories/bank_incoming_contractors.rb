FactoryBot.define do
  factory :bank_incoming_contractor do
    contractor_inn { 'MyString' }
    contractor_name { 'MyString' }
    vendor_id { nil }
  end
end
