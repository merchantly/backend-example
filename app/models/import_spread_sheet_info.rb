class ImportSpreadSheetInfo < ApplicationRecord
  extend Enumerize
  include TableColumns

  belongs_to :vendor

  serialize :column_definitions, Array
  serialize :result_messages, Array
  serialize :rows, Array

  validates :google_spreadsheet_url, presence: true, url: true

  enumerize :state, in: { none: 0, columns_defined: 1, process: 2, done: 3 }, predicates: true, default: :none

  before_create :save_rows

  def top_rows
    rows.slice(0, 3)
  end

  def seconds_per_row
    return unless imported_rows_count.positive? && total_rows_count.positive?

    (updated_at - created_at) / imported_rows_count.to_f
  end

  def speed_rows_per_hour
    return unless seconds_per_row

    3_600 / seconds_per_row
  end

  def estimated_time
    speed = speed_rows_per_hour
    return if speed.blank?

    Time.zone.now + ((left_rows / speed_rows_per_hour) * 3_600)
  end

  def left_rows
    total_rows_count - imported_rows_count
  end

  def last_row
    rows.last
  end

  def import!
    update_attribute :state, :process
    result = importer.perform do |row_index, imported_products_count|
      update imported_rows_count: row_index, imported_products_count: imported_products_count
    end
    update!(
      state: :done,
      imported_products_count: result[:imported_products_count],
      result_messages: result[:messages]
    )
  end

  private

  def importer
    @importer ||= build_importer
  end

  def build_importer
    ImportFromSpreadsheet.new(
      vendor: vendor,
      rows: rows,
      column_definitions: column_definitions,
      skip_rows: skip_rows,
      spreadsheet: spreadsheet
    )
  end

  def save_rows
    self.rows = spreadsheet.rows
    self.total_rows_count = spreadsheet.num_rows
    self.column_definitions = find_column_definitions spreadsheet.headers
  end

  def spreadsheet
    @spreadsheet ||= GoogleSpreadsheet.new(url: google_spreadsheet_url)
  end
end
