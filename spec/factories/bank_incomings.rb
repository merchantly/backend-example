FactoryBot.define do
  factory :bank_incoming do
    contractor_name { 'MyString' }
    contractor_inn { 'MyString' }
    amount { '' }
    bank_transaction_id { 'MyString' }
    title { 'MyString' }
    date { '2017-09-17' }
    state { 'MyString' }
  end
end
