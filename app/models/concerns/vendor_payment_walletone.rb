module VendorPaymentWalletone
  extend ActiveSupport::Concern

  PAYMENT_METHODS_LIST = YAML.load_file(Rails.root.join('config/w1_payment_methods.yml'))['methods']

  included do
    validate :w1_valid_payment_methods
  end

  def wmi_enabled_payment_methods_list
    wmi_enabled_payment_methods.join(', ')
  end

  def wmi_enabled_payment_methods_list=(list)
    self.wmi_enabled_payment_methods = list.split(/\s*,\s*/)
  end

  def wmi_disabled_payment_methods_list
    wmi_disabled_payment_methods.join(', ')
  end

  def wmi_disabled_payment_methods_list=(list)
    self.wmi_disabled_payment_methods = list.split(/\s*,\s*/)
  end

  private

  def w1_valid_payment_methods
    errors.add :wmi_enabled_payment_methods_list, I18n.t('errors.messages.inclusion') unless valid_list? wmi_enabled_payment_methods
    errors.add :wmi_disabled_payment_methods_list, I18n.t('errors.messages.inclusion') unless valid_list? wmi_disabled_payment_methods
  end

  def valid_list?(list)
    (list - PAYMENT_METHODS_LIST).blank?
  end
end
