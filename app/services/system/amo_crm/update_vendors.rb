require 'amo_crm'
require 'amo_crm/entities/custom_fields'

module System::AmoCRM
  class UpdateVendors < Base
    def perform
      # update_companies
      update_contacts
    end

    def update_contacts
      @updated_contacts = []
      @linked_company_not_found = []

      contacts = amocrm_universe.contacts.all
      contacts.each do |contact|
        contact_phone = find_phone contact
        contact_email = find_email contact

        if contact.linked_company_id.present?
          if linked_company = find_company(contact.linked_company_id)
            if vendor = Vendor.find_by(amocrm_company_id: linked_company.id)
              if member = vendor.members.includes(:operator).where(operators: { phone: contact_phone }).first
                amocrm_update_contact contact, member.operator, vendor
              else
                raise "Not found member #{contact.phone} in vendor #{vendor.id}"
              end
            else
              raise "Not found vendor #{linked_company.id}"
            end
          else
            @linked_company_not_found << contacts
          end
        else
          operator = Operator.find_by(amocrm_contact_id: contact.id) || Operator.find_by(phone: contact_phone) || Operator.find_by(email: contact_email)

          if operator.present?
            update_operator operator, contact
            amocrm_update_contact contact, operator, operator.vendors.first
          else
            raise "No operator found for #{contact_phone} and #{contact_email}"
          end

          # contact linked_company_id is blank
        end
      end

      {
        updated_contacts: @updated_contacts,
        linked_company_not_found: @linked_company_not_found
      }
    end

    def amocrm_update_contact(contact, operator, vendor)
      company = find_company vendor.amocrm_company_id

      return if contact.linked_company_id.to_s == company.id.to_s

      contact_custom_Fields = AmoCRM::CustomFields.new(
        CONTACT_CUSTOM_FIELD_OPERATOR_ID => "operator#{operator.id}"
      )

      update_contact = {
        id: contact.id,
        linked_company_id: company.try(:id),
        last_modified: contact.last_modified,
        tags: 'auto',
        custom_fields: contact_custom_Fields,
      }

      res = amocrm_client.post 'contacts/set', request: { contacts: { update: [update_contact] } }
      unless res.contacts[:update].first[:id] == contact.id
        raise "Update failed #{contact} #{update_contact} #{res}"
      end

      @updated_contacts << contact
    end

    def update_operator(operator, contact)
      raise 'Оператор имеет amocrm_contact_id' if operator.amocrm_contact_id.present? && operator.amocrm_contact_id.to_s != contact.id.to_s

      operator.update_column :amocrm_contact_id, contact.id
    end

    def update_companies
      @updated_companies = []
      @unknown_companies = []

      not_found = []
      updated_vendors = []

      messages = []

      companies.each do |company|
        host = get_custom_field_value(company.custom_fields, COMPANY_CUSTOM_FIELD_WEB, 'WEB')

        if host.present?
          uri = URI.parse host
          subdomain = uri.host.split('.')[0]
        else
          @unknown_companies << company
          next
        end

        if found_vendor = Vendor.find_by(amocrm_company_id: company.id)
          update_company company, found_vendor
        elsif found_vendor = Vendor.find_by(subdomain: subdomain)
          updated_vendors << found_vendor

          if found_vendor.amocrm_company_id.present?
            messages << "(subdomain) У магазина есть amocrm_company_id, однако по нему его не нашли vendor_id: #{found_vendor.id}, vendor.amocrm_company_id: #{found_vendor.amocrm_company_id}, company_id: #{company.id} - #{company.to_h}"
            next
          end

          found_vendor.update_columns amocrm_company_id: company.id
          update_company company, found_vendor
        elsif found_vendor = Vendor.find_by(domain: uri.host)
          updated_vendors << found_vendor

          if found_vendor.amocrm_company_id.present?
            messages << "(host) У магазина есть amocrm_company_id, однако по нему его не нашли vendor_id: #{found_vendor.id}, vendor.amocrm_company_id: #{found_vendor.amocrm_company_id}, company_id: #{company.id} - #{company.to_h}"
            next
          end

          found_vendor.update_columns amocrm_company_id: company.id
          update_company company, found_vendor
        else
          not_found << company
        end
      end

      {
        unknown_companies: @unknown_companies,
        updated_companies: @updated_companies,
        not_found: not_found,
        messages: messages
      }
    end

    private

    def contacts
      @contacts ||= amocrm_universe.contacts.all
    end

    def companies
      @companies ||= amocrm_universe.companies.all
    end

    def update_contact(_contact, _member)
      return if get_custom_field_value(company.custom_fields, COMPANY_CUSTOM_FIELD_SHOP_ID) == company_shop_id(vendor)

      company_custom_fields = AmoCRM::CustomFields.new(
        COMPANY_CUSTOM_FIELD_SHOP_ID => company_shop_id(vendor),
        COMPANY_CUSTOM_FIELD_WEB => [{ WEB: vendor.home_url }],
        CONTACT_CUSTOM_FIELD_EMAIL => [{ WORK: vendor.support_email }]
      )

      update_company = {
        name: vendor_company_name(vendor),
        id: company.id,
        last_modified: company.last_modified,
        tags: 'auto',
        custom_fields: company_custom_fields,
      }

      res = amocrm_client.post 'company/set', request: { contacts: { update: [update_company] } }
      unless res.contacts[:update].first[:id] == company.id
        raise "Update failed #{company} #{update_company} #{res}"
      end

      @updated_contacts << company
    end

    def update_company(company, vendor)
      return if get_custom_field_value(company.custom_fields, COMPANY_CUSTOM_FIELD_SHOP_ID) == company_shop_id(vendor)

      company_custom_fields = AmoCRM::CustomFields.new(
        COMPANY_CUSTOM_FIELD_SHOP_ID => company_shop_id(vendor),
        COMPANY_CUSTOM_FIELD_WEB => [{ WEB: vendor.home_url }],
        CONTACT_CUSTOM_FIELD_EMAIL => [{ WORK: vendor.support_email }]
      )

      update_company = {
        name: vendor_company_name(vendor),
        id: company.id,
        last_modified: company.last_modified,
        tags: 'auto',
        custom_fields: company_custom_fields,
      }

      res = amocrm_client.post 'company/set', request: { contacts: { update: [update_company] } }
      unless res.contacts[:update].first[:id] == company.id
        raise "Update failed #{company} #{update_company} #{res}"
      end

      @updated_companies << company
    end
  end
end
