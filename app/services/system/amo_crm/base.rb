module System::AmoCRM
  class Base
    private

    delegate :account, to: :amocrm

    def amocrm
      @amocrm ||= vendor.vendor_amocrm
    end

    def amocrm_universe
      System::AmoCRM.universe
    end

    def amocrm_client
      amocrm_universe.client
    end

    def vendor_company_name(vendor)
      "#{vendor.name} (#{vendor.subdomain})"
    end

    def company_shop_id(vendor)
      "shop#{vendor.id}"
    end

    def find_phone(object, code = nil)
      get_custom_field_value object.custom_fields, CUSTOM_FIELD_PHONE, code
    end

    def find_email(object, code = nil)
      get_custom_field_value object.custom_fields, CUSTOM_FIELD_EMAIL, code
    end

    def find_company(id)
      companies.find { |c| c.id == id }
    end

    def get_custom_field_value(custom_fields, custom_field_id, code = nil)
      raise 'custom_fields must be an Array' unless custom_fields.is_a? Array

      custom_field = find_custom_field(custom_fields, custom_field_id, code)

      return unless custom_field

      custom_field[:values].first[:value]
    end

    def find_custom_field(custom_fields, custom_field_id, code)
      raise 'custom_fields must be an Array' unless custom_fields.is_a? Array

      custom_fields.find { |c| c.id == custom_field_id.to_s && (code.nil? || c.code == code) }
    end

    def create_contact(name:, tags: [], company_name: nil, role: nil, operator_id: nil, lead_id: nil, email: nil, phone: nil)
      contact_custom_fields = AmoCRM::CustomFields.new(
        CONTACT_CUSTOM_FIELD_OPERATOR_ID => operator_id,
        CONTACT_CUSTOM_FIELD_EMAIL => [{ WORK: email }],
        CONTACT_CUSTOM_FIELD_PHONE => [{ MOB: phone }],
        CONTACT_CUSTOM_FIELD_ROLE => role
      )

      contact = {
        responsible_user_id: RESPONSIBLE_USER_ID,
        name: name,
        tags: tags,
        company_name: company_name,
        linked_leads_id: [lead_id],
        custom_fields: contact_custom_fields
      }

      res = amocrm_client.post 'contacts/set', request: { contacts: { add: [contact] } }
      res.contacts.add.first.id || raise("No contact id in response #{res}")
    end

    def create_lead(name:, responsible_user_id: RESPONSIBLE_USER_ID, tags: [], price: LEAD_DEFAULT_PRICE, pipeline_id: MAIN_PIPELINE_ID, source: nil, landing: nil, visitor_uid: nil)
      custom_fields = AmoCRM::CustomFields.new(
        LEAD_CUSTOM_FIELD_SOURCE => source,
        LEAD_CUSTOM_FIELD_LANDING => landing
      )

      tags += [:test, Rails.env] unless Rails.env.production?
      lead = {
        custom_fields: custom_fields,
        name: name,
        responsible_user_id: responsible_user_id,
        tags: tags.join(', '),
        price: price,
        pipeline_id: pipeline_id,
        visitor_uid: visitor_uid
      }

      res = amocrm_client.post 'leads/set', request: { leads: { add: [lead] } }

      res.leads.add.first.id || raise("No lead id in response #{res}")
    rescue StandardError => e
      Bugsnag.notify e, metaData: { secrets: Secrets.amocrm.to_s, login: System::AmoCRM.amocrm_login, apikey: System::AmoCRM.amocrm_apikey }
      raise e
    end
  end
end
