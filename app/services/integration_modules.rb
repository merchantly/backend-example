class IntegrationModules
  ALL = {
    payment: %i[walletone yandex_kassa cloud_payments rbk_money pay_pal robokassa tinkoff sberbank direct invoice gsdk arsenal_pay geidea_payment].freeze,
    online_kassa: %i[starrys atol life_pay orange_data cloud_kassir kassatka aqsi].freeze,
    crm: %i[amo_crm bitrix24].freeze,
    stock: %i[moysklad commerce_ml].freeze,
    analytics: %i[yandex_metrika google_analytics convead].freeze,
    import: %i[import_photos import_tables import_yml].freeze,
    export: %i[yandex_market torg_mail tasty export].freeze,
    comment: %i[disqus vkontakte facebook].freeze,
    other: %i[instagram apidoc ecr zatca].freeze,
    delivery: %i[cse ems redexpress pickup other digital russian_post yandex_delivery aramex cdek_delivery].freeze
  }.freeze

  class << self
    def enable?(integration)
      list.values.flatten.include? integration.to_s
    end

    def all
      IntegrationModules::ALL
    end

    def list
      Settings.integration_modules
    end

    def payments
      list.payment
    end

    def deliveries
      list.delivery
    end

    def online_kassa_enabled?
      list.online_kassa.present?
    end
  end
end
