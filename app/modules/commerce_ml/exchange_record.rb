require 'tempfile'
module CommerceML
  class ExchangeRecord < ApplicationRecord
    has_many :files, class_name: 'ExchangeRecordFile', dependent: :delete_all
    has_many :sales, class_name: 'CommerceML::ExchangeRecordSale', dependent: :delete_all
    has_many :orders, through: :sales

    scope :exported, -> { where export_status: :success }

    enum status: { checkauth: 0, init: 1, exchange: 2, done: 3, query: 4 }, _suffix: true
    enum export_status: { none: 0, query: 1, success: 2 }, _prefix: :export
    enum import_status: { none: 0, query: 1, success: 2 }, _prefix: :import

    before_create do
      self.cookie_value ||= generate_cookie_value
    end

    def add_file!(filename:, file:)
      f = Tempfile.new('sales')

      f.binmode
      f.write file.read
      f.close

      files.create! filename: filename, file: File.open(f.path)

      f.unlink
      update_status! :exchange
      update_import_status! :success
    end

    def update_status!(status)
      update_attribute :status, status
    end

    def update_import_status!(status)
      update_attribute :import_status, status
    end

    def update_export_status!(status)
      update_attribute :export_status, status
    end

    def success!
      update_status! :done
      update_export_status! :success
      Rails.logger.info "Отмечаем как экспортированные: #{sales.pluck(:order_id)}"
      sales.update_all is_exported: true
      orders.update_all ones_exported_at: updated_at
    end

    private

    def generate_cookie_value
      SecureRandom.uuid
    end
  end
end
