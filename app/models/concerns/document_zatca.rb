module DocumentZatca
  extend ActiveSupport::Concern

  NEW_ZATCA_STATE = 'new'.freeze
  PROCESS_ZATCA_STATE = 'process'.freeze
  SUCCESS_ZATCA_STATE = 'success'.freeze
  ERROR_ZATCA_STATE = 'error'.freeze
  ZATCA_STATES = [NEW_ZATCA_STATE, PROCESS_ZATCA_STATE, SUCCESS_ZATCA_STATE, ERROR_ZATCA_STATE].freeze

  INVOICE_URL = Settings['zatca'].present? ? Settings.zatca.invoices_printer_url : nil

  included do
    include WorkflowActiverecord

    workflow_column :zatca_state

    workflow do
      state NEW_ZATCA_STATE do
        event :zatca_process, transitions_to: PROCESS_ZATCA_STATE
      end
      state PROCESS_ZATCA_STATE do
        event :zatca_success, transitions_to: SUCCESS_ZATCA_STATE
        event :zatca_error, transitions_to: ERROR_ZATCA_STATE
        event :zatca_process, transitions_to: PROCESS_ZATCA_STATE
      end
      state ERROR_ZATCA_STATE do
        event :zatca_process, transitions_to: PROCESS_ZATCA_STATE
      end
      state SUCCESS_ZATCA_STATE
    end

    validates :zatca_state, inclusion: { in: ZATCA_STATES }, presence: true

    after_commit :send_zatca, on: :create
  end

  def invoice_present?
    zatca_invoice_id.present?
  end

  def invoice_pdf_url
    return if zatca_invoice_id.blank?

    "#{invoice_url}/pdf"
  end

  def invoice_qr_url
    return if zatca_invoice_id.blank?

    "#{invoice_url}/qr"
  end

  def invoice_url
    return if zatca_invoice_id.blank?

    "#{INVOICE_URL}/#{zatca_invoice_id}"
  end

  protected

  def zatca_error(response)
    data = {
      request_url: response.env.url,
      request_params: response.env.params,
      request_headers: response.env.request_headers,
      response_status: response.status,
      response_body: response.body,
      order_id: order.id
    }

    Bugsnag.notify "Zatca error order_id: #{order.id}", metaData: data
    Zatca.logger.error data.to_s
    update zatca_error: data
  end

  def zatca_success(invoice_id)
    update zatca_error: nil, zatca_invoice_id: invoice_id
  end

  private

  def send_zatca
    Zatca::PurchaseRequestor.perform_async id if vendor.zatca_enabled?
  end
end
