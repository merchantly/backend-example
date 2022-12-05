module OrderLogEntities
  extend ActiveSupport::Concern
  included do
    has_many :log_entities, class_name: 'OrderLogEntity'
  end

  def after_add_admin_comment(admin_comment)
    return unless admin_comment.persisted?

    System::AmoCRM::ExportOrder.delay.add_comment self, message if amocrm_lead_id.present?
  end

  def log!(key, payload = {})
    message = if key.is_a? Symbol
                I18n.t key, payload.merge(scope: :order_log_entities)
              else
                key
              end

    log_entities.create! author: author, message: message, dump: payload.as_json

    System::AmoCRM::ExportOrder.delay.add_comment self, message if amocrm_lead_id.present?
  rescue StandardError => e
    Bugsnag.notify e, metaData: { key: key, payload: payload.as_json, vendor_id: vendor_id }
  end
end
