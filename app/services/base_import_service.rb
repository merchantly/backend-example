class BaseImportService
  def self.read(file)
    # file.content_type содержит не всегда адекватные значения
    # например при загрузке CSV из linux отдает application/octet-stream
    case MimeMagic.by_extension(File.extname(file.original_filename)).type
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      Roo::Excelx.new(file.path, file_warning: :ignore).each

    when 'application/vnd.ms-excel'
      Roo::Excel.new(file.path, file_warning: :ignore).each

    when 'text/csv'
      HippieCSV.read(file.path).to_enum

    when 'text/csv/roo' # Таким образом его отключил. Использовался только для купонов
      default = {
        csv_options: {
          encoding: Encoding::CP1251,
          col_sep: ';'
        },
        file_warning: :ignore
      }
      Roo::CSV.new(file.path, default).each
    else
      raise "MIME Type #{file.content_type} is not supported"
    end
  end

  def initialize(vendor)
    @vendor       = vendor
    @row_number   = 0
  end

  # TODO Валидировать заголовок

  def perform(file:, skip_headers: true)
    raise 'Нет файла для загрузки' if file.blank?

    rows = self.class.read file
    ActiveRecord::Base.transaction do
      rows.each do |row|
        @current_row = row
        @row_number += 1
        next if @row_number == 1 && skip_headers.present?

        yield row
      end
    end
  rescue StandardError => e
    if @current_row.present?
      raise ImportError.new @row_number, "#{@current_row} <#{e.class}> #{e.message}"
    else
      raise ImportError.new @row_number, "<#{e.class}> #{e.message}"
    end
  end

  private

  attr_reader :vendor

  class ImportError < StandardError
    def initialize(row_number, message)
      super "Строка #{row_number}: #{message}"
    end
  end
end
