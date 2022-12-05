module System::AmoCRM
  class CreateLead < Base
    include Virtus.model strict: true

    attribute :lead, Lead

    def perform
      return if Rails.env.test?

      amocrm_lead_id = create_lead name: "Заявка с #{lead.landing_page_url}", landing: lead.landing_page_url, source: lead.referer

      amocrm_contact_id = create_contact lead_id: amocrm_lead_id, name: 'Anonymous', phone: lead.phone

      lead.update_columns amocrm_lead_id: amocrm_lead_id, amocrm_contact_id: amocrm_contact_id
    end
  end
end
