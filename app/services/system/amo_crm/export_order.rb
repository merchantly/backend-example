module System::AmoCRM
  class ExportOrder < Base
    include Virtus.model strict: true

    attribute :order, Order

    def self.add_comment(order, message)
      new(order: order).add_comment "kiiiosk: #{message}"
    end

    def perform(force: false)
      return if Rails.env.test?

      unless amocrm.present? && amocrm.is_active?
        Bugsnag.notify 'Vendor has no active amocrm', metaData: { order_id: order.id, vendor_id: order.vendor_id }
        return
      end

      raise "Заказ #{order.id} уже экспортирован в AmoCRM сделкой #{order.amocrm_lead_id}" if order.amocrm_lead_id.present? && !force

      lead_id = create_lead
      add_comment order.comment if order.comment.present?
      attach_client lead_id
      attach_goods lead_id

      Rails.logger.info "Created lead [#{lead_id}] in AmoCRM for order [#{order.id}]"
    rescue URI::BadURIError
      raise InvalidAmoCrmError
    rescue StandardError => e
      Bugsnag.notify e, metaData: { login: amocrm.login, apikey: amocrm.apikey }
      raise e
    end

    def add_comment(message)
      if order.amocrm_lead_id.present?
        amocrm.client.post 'notes/set', request: { notes: { add: [{ element_id: order.amocrm_lead_id, element_type: 2, note_type: 4, text: message }] } }
      else
        logger.error "В заказе #{order.id} не указан amocrm_lead_id и комментарий указать не возможно"
      end
    end

    class InvalidAmoCrmError < StandardError; end

    private

    def attach_goods(lead_id)
      GoodsLinker.new(order: order, lead_id: lead_id, catalog_id: vendor.vendor_amocrm.goods_catalog_id).perform if vendor.vendor_amocrm.enable_goods_linking?
    end

    def create_lead
      res = amocrm.client.post 'leads/set', request: { leads: { add: [lead] } }
      lead_id = res.leads.add.first.id || raise("No lead id in response #{res}")
      order.update_attribute :amocrm_lead_id, lead_id
      lead_id
    end

    def lead
      data = {
        name: "Заказ #{order.public_id} (#{order.vendor})",
        price: order.total_price.to_f
      }

      data[:responsible_user_id] = amocrm.responsible_user_id if amocrm.responsible_user_id.present?
      data[:tags] = amocrm.tags if amocrm.tags.present?
      data[:pipeline_id] = amocrm.pipeline_id if amocrm.pipeline_id.present?
      data[:status_id] = amocrm.initial_state_id if amocrm.initial_state_id.present?

      custom_fields = []

      if order.full_address.present? && amocrm.order_delivery_custom_field_id.present?
        custom_fields << { id: amocrm.order_delivery_custom_field_id, values: [{ value: order.full_address }] }
      end

      if order.weight.present? && amocrm.order_weight_custom_field_id.present?
        custom_fields << { id: amocrm.order_weight_custom_field_id, values: [{ value: order.weight }] }
      end

      data[:custom_fields] = custom_fields if custom_fields.any?

      data
    end

    def attach_client(lead_id)
      amocrm.client.post 'contacts/set', request: { contacts: { add: [amocrm_client.merge(linked_leads_id: lead_id)] } }
    end

    def amocrm_client
      @amocrm_client ||= {
        name: client.name,
        custom_fields: [
          {
            id: email_id,
            values: [
              {
                value: client.email.try(:email),
                enum: 'WORK'
              }
            ]
          },
          {
            id: phone_id,
            values: [
              {
                value: client.phone.phone,
                enum: 'WORK'
              }
            ]
          }
        ]
      }
    end

    def vendor
      @vendor ||= order.vendor
    end

    def client
      @client ||= order.client
    end

    def custom_fields
      @custom_fields ||= account['custom_fields']['contacts']
    end

    def email_id
      custom_fields.find { |f| f['code'] == 'EMAIL' }['id']
    end

    def phone_id
      custom_fields.find { |f| f['code'] == 'PHONE' }['id']
    end
  end
end
