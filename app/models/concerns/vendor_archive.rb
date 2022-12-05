module VendorArchive
  extend ActiveSupport::Concern
  ARCHIVE_PERIOD = Settings.archive_days.days
  PAYMENT_AFTER_NOTIFY_PERIOD = Settings.archive_notify_days.days

  included do
    # магазины которые необходимо уведомить о том что их магазин скоро будет перенесен в архив
    # не удален && не оплачен более 2 недель назад && не уведомлен
    scope :need_notify_shop_will_archive, lambda {
      shops.where(
        'not_archive = false ' \
        'AND archived_at IS NULL AND shop_will_archive_notified_at IS NULL ' \
        'AND (working_to < ? OR working_to is NULL) AND created_at < ?',
        Date.current - ARCHIVE_PERIOD,
        Date.current - ARCHIVE_PERIOD
      )
    }

    # магазины которые необходимо перенести в архив
    # не удален && не оплачен более 2 недель назад && уведомлен && прошло 3 дня после уведомления
    scope :need_archive, lambda {
      shops.where(
        'not_archive = false ' \
        'AND archived_at IS NULL AND shop_will_archive_notified_at IS NOT NULL ' \
        'AND (working_to < ? OR working_to is NULL)' \
        'AND shop_will_archive_notified_at < ?',
        Date.current - ARCHIVE_PERIOD,
        Date.current - ARCHIVE_PERIOD - PAYMENT_AFTER_NOTIFY_PERIOD
      )
    }

    scope :not_archive, -> { where(not_archive: true) }
  end
end
