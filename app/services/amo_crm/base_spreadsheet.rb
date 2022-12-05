module AmoCrm
  class BaseSpreadsheet < AbstractBaseSpreadsheet
    private

    def encoding
      'cp1251'
    end

    def lead_status(_vendor)
      'Не обработан'
    end

    def clean_string(buffer)
      buffer.tr("\t", ' ')
    end

    def full_name(vendor)
      vendor.vendor_walletone.full_name.presence || vendor.name
    end

    def email(vendor)
      vendor.owners.first.try(:email)
    end

    def manager(vendor)
      vendor.manager.try(:name)
    end
  end
end
