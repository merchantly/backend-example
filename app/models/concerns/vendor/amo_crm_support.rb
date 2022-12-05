module Vendor::AmoCRMSupport
  def amocrm_company_url
    if amocrm_company_id.present?
      "https://kiosk.amocrm.ru/companies/detail/#{amocrm_company_id}"
    else
      "https://kiosk.amocrm.ru/contacts/list/companies/?term=#{subdomain}"
    end
  end
end
