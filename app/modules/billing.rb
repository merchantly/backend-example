module Billing
  extend AutoLogger

  SYSTEM_CATEGORY_ID       = Settings::Billing.system_category_id
  CLIENTS_CATEGORY_ID      = Settings::Billing.clients_category_id
  CLIENTS_SMS_CATEGORY_ID  = Settings::Billing.clients_sms_category_id
  PARTNERS_CATEGORY_ID     = Settings::Billing.partners_category_id

  ECR_VENDOR_CASHIERS_CATEGORY_ID = Settings::Billing.ecr_vendor_cashiers_category_id
  ECR_VENDOR_CLIENTS_CATEGORY_ID  = Settings::Billing.ecr_vendor_clients_category_id
  ECR_VENDOR_EXPENSE_CATEGORY_ID = Settings::Billing.ecr_vendor_expense_category_id
  ECR_VENDOR_RECEIPT_CATEGORY_ID = Settings::Billing.ecr_vendor_receipt_category_id
  ECR_VENDOR_CORRECT_CATEGORY_ID = Settings::Billing.ecr_vendor_correct_category_id

  CLOUDPAYMENTS_ACCOUNT_ID = Settings::Billing.cloudpayments_account_id
  IP_PISMENNY_ACCOUNT_ID   = Settings::Billing.ip_pismenny_account_id
  WALLETONE_ACCOUNT_ID     = Settings::Billing.walletone_account_id
  PARTNER_ACCOUNT_ID       = Settings::Billing.partner_account_id
  SUBSCRIPTIONS_ACCOUNT_ID = Settings::Billing.subscriptions_account_id
  EXTERNAL_LINK_KIOSK_ACCOUNT_ID = Settings::Billing.external_link_kiosk_account_id
  ADDITIONAL_WORKS_ACCOUNT_ID = Settings::Billing.additional_works_account_id

  GSDK_ACCOUNT_ID = Settings::Billing.gsdk_account_id
  GSDK_GATEWAY_KEY = :gsdk

  ADDITIONAL_WORKS_SERVICE_ID = Settings::Billing.additional_works_service_id
  GIFT_ACCOUNT_ID = Settings::Billing.gift_account_id

  INCOMING_ACCOUNTS_IDS = [CLOUDPAYMENTS_ACCOUNT_ID, IP_PISMENNY_ACCOUNT_ID, WALLETONE_ACCOUNT_ID, GSDK_ACCOUNT_ID].freeze
  CLOUDPAYMENTS_GATEWAY_KEY = :cloudpayments

  SERVICES = {
    subscriptions: SUBSCRIPTIONS_ACCOUNT_ID,
    disable_kiosk_link: EXTERNAL_LINK_KIOSK_ACCOUNT_ID,
    additional_works: Billing::ADDITIONAL_WORKS_ACCOUNT_ID
  }.freeze

  SYSTEM_ACCOUNTS = {
    CLOUDPAYMENTS_GATEWAY_KEY => CLOUDPAYMENTS_ACCOUNT_ID,
    GSDK_GATEWAY_KEY => GSDK_ACCOUNT_ID,
    bank_ip_pismenny: IP_PISMENNY_ACCOUNT_ID,
    walletone: WALLETONE_ACCOUNT_ID,
    subscriptions: SUBSCRIPTIONS_ACCOUNT_ID,
    sms: Settings::Billing.sms,
    additional_works: Settings::Billing.additional_works,
    gift: GIFT_ACCOUNT_ID,
    external_link_kiosk: EXTERNAL_LINK_KIOSK_ACCOUNT_ID,
    moysklad: Settings::Billing.moysklad,
    partners: PARTNER_ACCOUNT_ID
  }.freeze

  def self.incoming_accounts
    OpenbillAccount.where(id: INCOMING_ACCOUNTS_IDS)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
