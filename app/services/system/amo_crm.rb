require 'amo_crm'
require 'amo_crm/entities/custom_fields'

module System
  module AmoCRM
    MAIN_PIPELINE_ID = 229_245

    LEAD_DEFAULT_PRICE = 1000

    CUSTOM_FIELD_PHONE = 197_633
    CUSTOM_FIELD_EMAIL = 197_635

    LEAD_CUSTOM_FIELD_SOURCE = 276_925
    LEAD_CUSTOM_FIELD_LANDING = 276_923

    CONTACT_CUSTOM_FIELD_PHONE = CUSTOM_FIELD_PHONE
    CONTACT_CUSTOM_FIELD_EMAIL = CUSTOM_FIELD_EMAIL
    CONTACT_CUSTOM_FIELD_OPERATOR_ID = 219_435
    CONTACT_CUSTOM_FIELD_ROLE = 197_631 # POSITION

    COMPANY_CUSTOM_FIELD_PHONE = CONTACT_CUSTOM_FIELD_PHONE
    COMPANY_CUSTOM_FIELD_EMAIL = CONTACT_CUSTOM_FIELD_EMAIL
    COMPANY_CUSTOM_FIELD_WEB   = 197_637
    COMPANY_CUSTOM_FIELD_ADDRESS = 197_641
    COMPANY_CUSTOM_FIELD_SHOP_ID = 219_433

    RESPONSIBLE_USER_ID = 915_013 # Костя

    def self.universe
      @universe ||= ::AmoCRM::Universe.build user_login: amocrm_login, user_hash: amocrm_apikey, url: amocrm_url
    end

    def self.amocrm_url
      ENV['AMOCRM_URL'].presence || Secrets.amocrm.url || 'https://kiosk.amocrm.ru'
    end

    def self.amocrm_login
      ENV['AMOCRM_LOGIN'].presence || Secrets.amocrm.login
    end

    def self.amocrm_apikey
      ENV['AMOCRM_APIKEY'].presence || Secrets.amocrm.apikey
    end
  end
end
