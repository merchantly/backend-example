# Подключаем fixture_upload
include ActionDispatch::TestProcess

FactoryBot.define do
  factory :vendor do
    yandex_kassa_secret { '123456789' }
    working_to { Date.current + 1.week }
    is_pre_create { false }
    tax_type { 'tax_ru_1' }
    tax_mode { 1 }
    domain_zone { Settings.domain_zones.first }

    sequence :name do |n|
      "Компания #{n}"
    end

    sequence :subdomain do |n|
      "company#{n}#{Time.zone.now.to_i}"
    end

    sequence :domain do |n|
      "company#{n}#{Time.zone.now.to_i}.ru"
    end

    trait :with_default_cashier do
      after :create do |vendor|
        cashier = vendor.cashiers.create! name: I18n.t('services.vendor_registration.default_cashier')

        vendor.update_column :default_cashier_id, cashier.id
      end
    end

    trait :with_tariff do
      after :build do |vendor|
        vendor.tariff = create :tariff
      end
    end

    trait :with_billing do
      # after :build do |vendor|
      # vendor.class.set_callback(:commit, :after, :billing_account)
      # end
    end

    trait :with_payment_account do
      transient do
        payment_token { '123' }
      end
      after :create do |vendor, opts|
        vendor.payment_accounts.create! token: opts.payment_token,
                                        card_first_six: '123456',
                                        card_last_four: '9999',
                                        card_type: 'visa',
                                        card_exp_date: '01/30',
                                        gateway: :cloudpayments
      end
    end

    trait :with_minimal_price do
      after :create do |vendor|
        vendor.update minimal_price: Money.new(4000)
      end
    end

    trait :with_rbk_money do
      rbk_money_eshop_id { '1' }
      rbk_money_secret { '123' }
    end

    trait :with_amocrm do
      after :create do |vendor|
        vendor.create_vendor_amocrm!(
          is_active: true,
          login: 'test',
          apikey: 'test',
          url: 'http://test.amocrm.ru.localhost',
          enable_goods_linking: true,
          goods_catalog_id: 1,
          goods_catalog_moysklad_custom_field_id: 2
        )
      end
    end

    trait :with_w1_auth do
      after(:build) do |vendor|
        vendor.class.skip_callback(:create, :after, :create_walletone!)
      end

      after(:create) do |vendor|
        w1 = create(:vendor_walletone, vendor: vendor)
        vendor.authentications.create! provider: :walletone,
                                       uid: w1.merchant_id,
                                       auth_hash: { credentials: { token: :access_token, expires: 30.minutes.since } }.as_json
        vendor.class.set_callback(:create, :after, :create_walletone!)
      end
    end

    trait :w1_not_approved do
      after(:build) do |vendor|
        vendor.class.skip_callback(:create, :after, :create_walletone!)
      end

      after(:create) do |vendor|
        create(:vendor_walletone, :not_approved, vendor: vendor)
        vendor.class.set_callback(:create, :after, :create_walletone!)
      end
    end

    trait :w1_expired_token do
      after(:build) do |vendor|
        vendor.class.skip_callback(:create, :after, :create_walletone!)
      end

      after(:create) do |vendor|
        w1 = create(:vendor_walletone, vendor: vendor)
        vendor.authentications.create provider: :walletone,
                                      uid: w1.merchant_id,
                                      auth_hash: { credentials: { token: :access_token, expires: 10.minutes.ago } }.as_json
        vendor.class.set_callback(:create, :after, :create_walletone!)
      end
    end

    trait :with_w1 do
      transient do
        w1_md5_secret_key { '' }
      end
      after :create do |vendor, evaluator|
        vendor.vendor_walletone.update merchant_sign_key: evaluator.w1_md5_secret_key
      end
    end

    trait :moysklad do
      moysklad_login { 'login' }
      moysklad_password { 'password' }
    end

    trait :yandex_kassa do
      yandex_kassa_enabled { true }
      yandex_kassa_shop_id { '1234' }
    end

    trait :country_kz do
      remote_ip { '2.79.255.255' }
    end

    trait :country_au do
      remote_ip { '1.1.1.1' }
    end

    trait :with_products do
      transient do
        items_count { 3 }
      end
      after :create do |vendor, evaluator|
        vendor.products << build_list(:product, evaluator.items_count, vendor: vendor)
      end
    end

    trait :with_ordering_products do
      transient do
        items_count { 3 }
      end
      after :create do |vendor, evaluator|
        vendor.products << build_list(:product, evaluator.items_count, :ordering, vendor: vendor)
      end
    end

    trait :with_sms_log_entities do
      transient do
        items_count { 3 }
      end
      after :create do |vendor, evaluator|
        vendor.vendor_sms_log_entities << build_list(:vendor_sms_log_entity, evaluator.items_count, vendor: vendor)
      end
    end

    trait :with_clients do
      transient do
        items_count { 3 }
      end
      after :create do |vendor, evaluator|
        vendor.clients << create_list(:client, evaluator.items_count, vendor: vendor)
      end
    end

    trait :with_individual_tariff do
      after :create do |vendor|
        vendor.tariff = TariffIndividual.create(title: 'title')
      end
    end

    trait :with_operator do
      after :create do |vendor|
        vendor.operators << create(:operator)
      end
    end

    trait :with_public_offer do
      after :create do |vendor|
        page = create(:content_page, is_active: true)
        vendor.content_pages << page
        vendor.update_column :public_offer_page_id, page.id
      end
    end

    trait :currency_eur do
      currency_iso_code { 'EUR' }
    end

    trait :product_with_property do
      after :create do |vendor|
        create :product, :property, vendor: vendor
      end
    end

    trait :with_theme do
      # after(:build) do |vendor|
      #   vendor.class.skip_callback(:create, :after, :create_theme!)
      # end
      # after(:create) do |vendor|
      #   create(:vendor_theme, vendor: vendor)
      #   vendor.reload
      #   vendor.class.set_callback(:create, :after, :create_theme!)
      # end
    end

    trait :payment do
      after :create do |vendor|
        create :vendor_payment, :direct, vendor: vendor, title: vendor.name
      end
    end

    trait :payments_and_deliveries do
      after :create do |vendor|
        create :vendor_payment, :direct, vendor: vendor, title: vendor.name
        create :vendor_delivery, :other, vendor: vendor, title: vendor.name, free_delivery_threshold: Money.new(10)
      end
    end

    trait :payments_and_deliveries_remote do
      after :create do |vendor|
        create :vendor_payment, :w1, vendor: vendor, title: vendor.name
        create :vendor_delivery, :cse, vendor: vendor, title: vendor.name
      end
    end

    trait :delivery do
      after :create do |vendor|
        create :vendor_delivery, :cse, vendor: vendor, title: vendor.name
      end
    end

    trait :with_package_category do
      after :create do |vendor|
        vendor.update_attribute :package_category_id,
                                create(:category, :products, vendor: vendor).id
      end
    end

    trait :demo do
      after :create do |vendor|
        vendor.update_column :subdomain, 'demo'
      end
    end

    sellable_infinity { false }
    support_email { 'vendor@test.test' }

    trait :with_common_filter_options do
      show_filter_availability { true }
      show_filter_price_range { true }
    end

    trait :with_orders do
      transient do
        orders_count { 3 }
      end
      after :create do |vendor, evaluator|
        vendor.orders << create_list(:order, evaluator.orders_count, vendor: vendor)
      end
    end

    trait :with_default_order_conditions do
      after :create do |vendor, _evaluator|
        DefaultOrderConditions.new(vendor).perform
      end
    end
  end
end
