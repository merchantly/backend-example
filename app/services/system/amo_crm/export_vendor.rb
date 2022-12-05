module System::AmoCRM
  # auto - означает что запись в AmoCRM создана автоматически
  # kiiiosk.store - означает что эта запись из киоска (будут и другие)
  TAGS = [:auto].freeze

  class ExportVendor < Base
    include Virtus.model strict: true

    attribute :owner, Member
    attribute :vendor, Vendor

    def perform
      return if Rails.env.test?
      return if Secrets.amocrm.blank?

      lead_id = create_lead name: 'Регистрация на kiiiosk.store', tags: tags, source: 'kiiiosk.store'

      company_id = create_company lead_id: lead_id

      vendor.update_columns(
        amocrm_lead_id: lead_id,
        amocrm_company_id: company_id
      )

      contact_id = create_contact(
        lead_id: lead_id,
        name: owner.name,
        email: owner.email,
        phone: owner.phone,
        operator_id: owner.id,
        role: owner.role.title,
        tags: tags,
        company_name: vendor_company_name(vendor)
      )

      owner.operator.update_columns(
        amocrm_contact_id: contact_id
      )
    end

    private

    attr_reader :vendor, :owner

    def create_company(lead_id:)
      company_custom_fields = AmoCRM::CustomFields.new(
        COMPANY_CUSTOM_FIELD_SHOP_ID => "shop#{vendor.id}",
        COMPANY_CUSTOM_FIELD_WEB => [{ WEB: vendor.host }],
        CONTACT_CUSTOM_FIELD_EMAIL => [{ WORK: vendor.support_email }]
      )

      company = {
        name: vendor_company_name(vendor),
        responsible_user_id: RESPONSIBLE_USER_ID,
        tags: tags.join(', '),
        custom_fields: company_custom_fields,
        linked_leads_id: [lead_id]
      }

      res = amocrm_client.post 'company/set', request: { contacts: { add: [company] } }
      res.contacts.add.first.id || raise("No contact id in response #{res}")
    end

    def tags
      list = []
      list += TAGS
      list << Rails.env unless Rails.env.production?
      list
    end
  end
end
