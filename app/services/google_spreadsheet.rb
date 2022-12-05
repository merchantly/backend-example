class GoogleSpreadsheet
  include Virtus::Model

  attribute :url, String

  delegate :num_rows, :rows, :numeric_value, to: :worksheet

  def headers
    @headers ||= rows[0]
  end

  private

  def worksheet
    @worksheet ||= spreadsheet.worksheets.first
  end

  def spreadsheet
    @spreadsheet = session.spreadsheet_by_url url
  end

  def session
    @session ||= GoogleDrive::Session.from_service_account_key('./config/google_service_account.json')
  end
end
