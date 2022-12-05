# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :openbill_transaction do
    date { Date.current }
    # to_account { create(:vendor).common_billing_account }
    amount { Money.new(100, :rub) }
    details { 'test' }
    key { "test-#{Time.zone.now.to_i}" }
    meta { {} }
  end
end
