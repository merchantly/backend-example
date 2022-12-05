# Это сервис для управления колокольчиками (сигналами)
# вендора.
#
# * Если у вендора нет ни одной доставки и способа оплаты-клиенты не смогут ничего купить
# * Если не установлен текст адреса самовывоза - не возможно купить самовывозом (у первых вендоров его нет и покупки не возможны)
# * Если у пользователя еще нет пароля
# * Если нет ни одной совместимой доставки и оплаты

module VendorBells
  class Dispatcher
    include Virtus.model strict: true
    attribute :vendor, Vendor, required: true

    EXPIRED_PERIOD = 1.hour
    DISABLE_MAX_COUNT = 3
    DISABLE_PERIOD = 1.day

    def add_error(bell_error, opts = {})
      add bell_error.class.name, opts
    end

    def add(bell_key, opts = {})
      bell_key = bell_key.to_s

      bell = vendor.bells.where('updated_at > ? and key = ?', EXPIRED_PERIOD.ago, bell_key).last

      if bell.present?
        VendorBells::VendorBell.increment_counter :count, bell.id
        bell.touch
        bell
      else
        vendor.bells.create! key: bell_key, options: opts
      end

      disable_service bell_key
    end

    def disable_service(bell_key)
      bells_count = vendor.bells.where('updated_at > ? and key = ?', DISABLE_PERIOD.ago, bell_key).count

      return if bells_count < DISABLE_MAX_COUNT

      case bell_key.to_sym
      when :convead_invalid_or_outdate
        vendor.update convead_app_key: nil
        vendor.bells.create! key: :disable_convead
      end
    end

    def clear!
      vendor.bells.destroy_all
    end

    def read_all!(ids = [])
      vendor.bells.fresh.where(id: ids).update_all read_at: Time.zone.now
    end
  end
end
