# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :cloud_payments_transaction, class: 'CloudPayments::Transaction' do
    initialize_with do
      new(
        metadata: nil,
        id: 19_292_355,
        amount: 1.0,
        currency: 'RUB',
        currency_code: 0,
        invoice_id: 'unknown',
        account_id: 'unknown',
        email: nil,
        description: 'Оплата обслуживания интернет магазина http://demo.3001.brandymint.ru',
        created_at: Time.zone.now,
        authorized_at: Time.zone.now,
        confirmed_at: Time.zone.now,
        auth_code: 'A1B2C3',
        test_mode: true,
        ip_address: '46.73.130.128',
        ip_country: 'RU',
        ip_city: 'Москва',
        ip_region: 'Москва',
        ip_district: 'Центральный федеральный округ',
        ip_lat: 55.755787,
        ip_lng: 37.617634,
        card_first_six: '424242',
        card_last_four: '4242',
        card_exp_date: '01/18',
        card_type: 'Visa',
        issuer_bank_country: nil,
        card_type_code: 0,
        status: 'Completed',
        status_code: 3,
        reason: 'Approved',
        reason_code: 0,
        card_holder_message: 'Оплата успешно проведена',
        name: nil,
        token: '477BBA133C182267FE5F086924ABDC5DB71F77BFC27F01F2843F2CDC69D89F05',
        subscription_id: nil
      )
    end
  end
end
