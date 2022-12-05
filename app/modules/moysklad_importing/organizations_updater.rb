module MoyskladImporting
  class OrganizationsUpdater < Updater
    private

    def resource
      vendor.moysklad_universe.organizations.all
    end

    def scope(_entity = nil)
      vendor.vendor_organizations
    end

    def archive_all_remains
      super

      if vendor.vendor_organization.blank?
        vendor.update!(
          vendor_organization: scope.alive.first
        )
      end
    end

    def default_attributes(entity, model)
      attrs = super entity, model

      attrs.merge(
        name: entity.name,
        company_type: entity.companyType,
        legal_title: entity.legalTitle,
        legal_address: entity.legalAddress,
        inn: entity.inn,
        okpo: entity.okpo,
        email: entity.email,
        phone: entity.phone,
        director: entity.director,
        is_payer_vat: entity.payerVat,
        is_egais_enabled: entity.isEgaisEnable
      )
    end
  end
end
