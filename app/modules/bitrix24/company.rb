module Bitrix24
  module Company
    def company_id(company)
      return company.bitrix24_id if company.bitrix24_id.present?

      result = add_company(company)

      raise "Ошибка добавления компании в bitrix24: #{result}" if result['error_description'].present?

      company.update_column :bitrix24_id, result['result']
      company.bitrix24_id
    end

    def add_company(company)
      params = {
        fields: {
          TITLE: company.name,
          COMPANY_TYPE: 'CUSTOMER',
          ADDRESS: company.last_order.full_address,
          HAS_PHONE: (company.phone.present? ? 'Y' : 'N'),
          HAS_EMAIL: (company.email.present? ? 'Y' : 'N'),
          ASSIGNED_BY_ID: manager_id(vendor_bitrix24.responsible_manager),
          PHONE: [{ VALUE: company.phone, VALUE_TYPE: 'WORK' }],
          EMAIL: [{ VALUE: company.email, VALUE_TYPE: 'WORK' }],
        }
      }

      Bitrix24CloudApi::CRM::Company.add(client, params)
    end
  end
end
