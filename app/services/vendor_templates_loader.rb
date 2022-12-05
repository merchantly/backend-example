class VendorTemplatesLoader
  TEMPLATES_DIR = Rails.root.join('db/vendor_templates')

  RECORDS = [
    Vendor,
    VendorTemplate,
    Tag,
    Category,
    Dictionary,
    DictionaryEntity,
    Product,
    ContentPage,
    Lookbook,
    SliderImage,
    VendorPayment,
    VendorDelivery,
    Order,
    WorkflowState,
    Property,
    OpenbillAccount,
    Role,
    PriceKind,
    ClientCategory,
    QuantityUnit,
    VendorTheme
  ].freeze

  class << self
    def import
      # disable triggers of foreign keys
      connection.execute("SET session_replication_role = 'replica';")

      RECORDS.each do |record|
        puts "Import #{record}"
        record.copy_from TEMPLATES_DIR.join("#{record.table_name}.csv").to_s

        # correct sequences
        connection.execute("select setval('#{record.table_name}_id_seq', max(id)) from #{record.table_name};") if record.columns_hash['id'].type == :integer
      end

      connection.execute("SET session_replication_role = 'origin';")
    rescue StandardError => e
      connection.execute("SET session_replication_role = 'origin';")

      raise e
    end

    def export
      FileUtils.mkdir_p TEMPLATES_DIR

      vendor_ids = VendorTemplate.pluck(:vendor_id)

      RECORDS.each do |record|
        puts "Export #{record}"

        File.open(TEMPLATES_DIR.join("#{record.table_name}.csv"), 'w') do |f|
          scope = case record.to_s
                  when 'VendorTemplate'
                    record.all
                  when 'Vendor'
                    record.where(id: vendor_ids)
                  when 'OpenbillAccount'
                    record.where(reference_id: vendor_ids, reference_type: 'Vendor')
                  else
                    record.where(vendor_id: vendor_ids)
                  end

          # record.copy_to export all entities, so use our solution
          connection.raw_connection.copy_data "COPY (#{scope.to_sql}) TO STDOUT WITH DELIMITER ',' CSV HEADER" do
            while (line = connection.raw_connection.get_copy_data)
              f.write line.force_encoding('utf-8')
            end
          end
        end
      end
    end

    private

    def connection
      ApplicationRecord.connection
    end
  end
end
