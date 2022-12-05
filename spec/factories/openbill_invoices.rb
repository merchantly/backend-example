# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :openbill_invoice do
    date { Date.current }
    is_autochargable { true }
    destination_account { create(:vendor).common_billing_account }
    title { 'Оплата обслуживания' }
    amount { Money.new(100, :rub) }
    sequence :number do |n|
      n
    end
  end
end
