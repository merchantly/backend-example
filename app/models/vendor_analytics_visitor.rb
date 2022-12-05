# Посетитель магазина
# Фактические это сочетание vendor_id и session_id пользователя

class VendorAnalyticsVisitor < ApplicationRecord
  belongs_to :vendor
  belongs_to :session

  def self.safe_create(vendor_id:, session_id:, first_visit_id:, created_at:)
    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, session_id, first_visit_id, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (vendor_id, session_id) DO NOTHING
    }

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              sql,
              vendor_id, session_id, first_visit_id, created_at
            ])

    connection.execute query
  end
end
