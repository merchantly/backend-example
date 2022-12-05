class VendorAnalyticsVisitToSource < ApplicationRecord
  belongs_to :vendor
  belongs_to :source, class_name: 'VendorAnalyticsSource'

  def self.safe_create(vendor_id:, visit_id:, session_id:, source_id:, created_at:)
    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, visit_id, session_id, source_id, created_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT (vendor_id, session_id, visit_id, source_id)
      DO NOTHING
    }

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              sql,
              vendor_id, session_id, visit_id, source_id, created_at
            ])

    connection.execute query
  end
end
