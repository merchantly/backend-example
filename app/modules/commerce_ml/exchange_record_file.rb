require 'zip'
require 'nokogiri'

class CommerceML::ExchangeRecordFile < ApplicationRecord
  belongs_to :exchange_record, counter_cache: :files_count, touch: true

  mount_uploader :file, CommerceML::ExchangeUploader
  mount_uploaders :extracted_files, CommerceML::ExchangeUploader

  after_commit :extract_files, on: :create

  def doc
    @doc ||= open_xml
  end

  def extract_files
    delay.extract_files!
  end

  def extract_files!
    files = []

    Zip::File.open file.file.file do |zip_file|
      zip_file.each do |entry|
        entry_file_name = File.join(file.root, file.store_dir, entry.name)
        Rails.logger.info "Extract #{file.file.file} into #{entry_file_name}"
        entry.extract entry_file_name
        files << entry_file_name
      end
    end

    update!(
      extracted_files: files.map { |f| Pathname.new(f).open },
      extraction_result: 'ok'
    )
  end

  private

  def extracted_file
    extracted_files.first.file.file
  end

  def open_xml
    File.open(extracted_file) { |f| Nokogiri::XML(f) }
  end
end
