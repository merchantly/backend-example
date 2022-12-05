module MoyskladImporting
  class ClientsUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.counterparties.all
    end

    def scope(_entity = nil)
      vendor.clients
    end

    def find_model(entity)
      find_scope(entity).by_ms_entity(entity).take ||
        find_scope(entity).by_phone_or_email(entity.phone, entity.email)
    end

    def create_or_update(entity)
      if vendor.is_sync_clients_create?
        if entity.phone.blank?
          vendor_logger.info message: "У клиента #{entity.id} нет телефона"
          return
        end

        unless Phoner::Phone.valid?(entity.phone)
          vendor_logger.info message: "У клиента #{entity.id} некорректный номер телефона #{entity.phone}"
          return
        end

        if entity.email.present? && !ValidateEmail.valid?(entity.email)
          vendor_logger.info message: "У клиента #{entity.id} некорректный email #{entity.emai}"
          return
        end

        return super(entity)
      end

      model = find_model(entity)

      return if model.blank?

      model.assign_attributes default_attributes(entity, model)

      RepeatDeadLock.perform do
        update_from_moysklad model, entity
      end

      model
    end

    def default_attributes(entity, model)
      attrs = super(entity, model)

      attrs = attrs.merge(
        name: entity.name,
        address: entity.actualAddress,
        inn: entity.inn,
        kpp: entity.kpp,
        ogrn: entity.ogrn,
        okpo: entity.okpo,
        description: entity.description,
        legal_title: entity.legalTitle
      )

      if model.new_record?
        attrs = attrs.merge(
          phones_attributes: { 0 => { phone: entity.phone } },
          emails_attributes: { 0 => { email: entity.email } }
        )
      end

      attrs
    end
  end
end
