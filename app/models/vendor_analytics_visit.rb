class VendorAnalyticsVisit < ApplicationRecord
  belongs_to :vendor
  belongs_to :visitor

  def self.safe_create(id:, vendor_id:, session_id:, user_agent:, referer:, remote_ip:, params:, sources_ids:, created_at:)
    sql = %{
      INSERT INTO #{table_name}
      (id, vendor_id, session_id, user_agent, referer, remote_ip, params, sources_ids, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (id) DO NOTHING RETURNING ID
    }

    # VALUES (?, ?, ?, ?, ?, ?, ?, ARRAY#{sources_ids.compact}, ?)
    params = params.to_json if params.is_a? Hash

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              sql,
              id, vendor_id, session_id, user_agent, referer, remote_ip, params, "{#{sources_ids.compact.join(',')}}", created_at
            ])

    res = connection.execute query

    res.first['id']
  end
end
