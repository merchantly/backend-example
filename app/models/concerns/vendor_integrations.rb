module VendorIntegrations
  def has_integration?(integration)
    case integration.key
    when :walletone
      w1_on?
    when :vkontakte, :facebook
      authentications.exists?(provider: integration.key)
    when :moysklad
      ms_valid?
    when :google_analytics
      google_analytics_tracking_id.present?
    when :yandex_metrika
      yandex_metrika_tracking_id.present?
    when :convead
      use_convead?
    when :tasty
      tasty_user_token.present?
    when :yandex_market
      yandex_market_enabled?
    when :torg_mail
      torg_mail_enabled?
    when :amo_crm
      vendor_amocrm.try(:is_active?)
    when :bitrix24
      vendor_bitrix24.try(:is_active?)
    when :disqus
      disqus_url.present?
    when :pay_pal
      pay_pal_email.present?
    when :yandex_kassa
      yandex_kassa_shop_id.present?
    when :rbk_money
      rbk_money_eshop_id.present?
    when :cloud_payments
      vendor_payments.alive.where(payment_agent_type: OrderPaymentCloudPayments.name).any?
    when :robokassa
      vendor_payments.alive.where(payment_agent_type: OrderPaymentRobokassa.name).any?
    when :tinkoff
      vendor_payments.alive.where(payment_agent_type: OrderPaymentTinkoff.name).any?
    when :sberbank
      vendor_payments.alive.where(payment_agent_type: OrderPaymentSberbank.name).any?
    when :arsenal_pay
      vendor_payments.alive.where(payment_agent_type: OrderPaymentArsenalPay.name).any?
    when :apidoc, :export, :import, :import_photos, :import_tables, :import_yml
      true
    when :starrys
      vendor_payments.alive.where(online_kassa_provider: :starrys).any?
    when :atol
      vendor_payments.alive.where(online_kassa_provider: :default).any?
    when :kassatka
      vendor_payments.alive.where(online_kassa_provider: :kassatka).any?
    when :aqsi
      vendor_payments.alive.where(online_kassa_provider: :aqsi).any?
    when :commerce_ml
      commerce_ml_configuration.present?
    when :zatca
      zatca_enabled?
    when :vkontakte_export, :life_pay, :orange_data, :cloud_kassir, :instagram
      # TODO
    else
      raise "Unknown integration: #{integration.key}"
    end
  end
end
