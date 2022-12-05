# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :workflow_state do
    name { 'MyString' }
    color_hex { '#337788' }
    finite_state { 'in_process' }
    vendor
  end
end
