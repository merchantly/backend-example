module VendorMoysklad
  extend ActiveSupport::Concern
  SYNCING_PERIOD = 60.minutes

  def moysklad_password=(password)
    super password if password.present?
  end

  def ms_valid?
    moysklad_login.present? && moysklad_password.present?
  end

  def reserve_order_on_stock?
    ms_valid? && reserve_on_linked_stock?
  end

  # Товары залинкованы со складом и их нет смысла пеертаскивать или изменять
  def categories_linked?
    ms_valid? && is_stock_do_sync_categories?
  end

  # В процессе синхронизации?
  def moysklad_in_syncing?
    stock_importing_log_entities.started.any?
  end

  def long_not_syncing?
    stock_success_synced_at.nil? || (Time.zone.now - stock_success_synced_at) > SYNCING_PERIOD
  end

  # Just a shortcut
  #
  def moysklad_import(*args)
    MoyskladImporting::Processor.build(self).perform(*args)
  end

  def moysklad_universe
    @moysklad_universe ||= Moysklad::Universe.build login: moysklad_login, password: moysklad_password
  end

  def moysklad_auto_sync_available?
    ms_valid? && stock_auto_syncing?
  end
end
