class ClientsImporter
  class Result
    include Virtus.model

    attribute :total_rows_count, Integer
    attribute :imported_clients_count, Integer
    attribute :errors, Array[Hash]
  end

  COLUMNS = %i[name phones emails address city_title area street house floor room].freeze

  def initialize(form:, vendor:)
    @form = form
    @vendor = vendor
  end

  def perform
    clients_attrs.each_with_index do |client_attrs, index|
        client = find_client client_attrs

        if client.present?
          client_attrs[:emails_attributes].delete_if { |email| client.emails.exists?(email: email[:email]) } if client_attrs[:emails_attributes].present?
          client_attrs[:phones_attributes].delete_if { |phone| client.phones.exists?(phone: phone[:phone]) } if client_attrs[:phones_attributes].present?

          client.update! client_attrs
        else
          vendor.clients.create! client_attrs
        end

        result.imported_clients_count += 1
    rescue StandardError => e
        result.errors << { row_num: index, message: e.message, row: client_attrs }
    end

    result
  end

  private

  attr_reader :form, :vendor

  delegate :google_spreadsheet_url, :headers_language, to: :form

  def result
    @result ||= Result.new(total_rows_count: spreadsheet.num_rows, imported_clients_count: 0, errors: [])
  end

  def clients_attrs
    @clients_attrs ||= build_clients_attrs
  end

  def build_clients_attrs
    attrs = []

    spreadsheet.rows.each do |row|
      next if row.blank? || (row == spreadsheet_headers)

      client_attrs = {}
      columns.each_with_index do |col, index|
        next if col.blank?

        case col
        when :emails
          client_attrs[:emails_attributes] = row[index].split(',').map { |email| { email: email.strip.downcase } }
        when :phones
          client_attrs[:phones_attributes] = row[index].split(',').map { |phone| { phone: Phoner::Phone.parse(phone).to_s } }
        else
          client_attrs[col] = row[index]
        end
      end

      attrs << client_attrs
    end

    attrs
  end

  def spreadsheet
    @spreadsheet ||= GoogleSpreadsheet.new(url: google_spreadsheet_url)
  end

  def spreadsheet_headers
    @spreadsheet_headers ||= spreadsheet.headers
  end

  def columns
    @columns ||= build_columns
  end

  def build_columns
    spreadsheet.headers.map do |col|
      tr_columns[col]
    end
  end

  def tr_columns
    @tr_columns ||= COLUMNS.index_by { |column| I18n.t(column, scope: %i[clients_google_spreadsheet columns], locale: headers_language) }
  end

  def find_client(client_attrs)
    raise 'Client does not have phone or email' if client_attrs[:phones_attributes].blank? && client_attrs[:emails_attributes].blank?

    client = nil

    if client_attrs[:phones_attributes].present?
      client = vendor.clients.joins(:phones).where(client_phones: { phone: client_attrs[:phones_attributes].pluck(:phone) }).first
    end

    if client.blank? && client_attrs[:emails_attributes].present?
      client = vendor.clients.joins(:emails).where(client_emails: { email: client_attrs[:emails_attributes].pluck(:email) }).first
    end

    client
  end
end
