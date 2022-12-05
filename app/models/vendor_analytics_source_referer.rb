class VendorAnalyticsSourceReferer < VendorAnalyticsSource
  validates :referer, presence: true

  def self.safe_create(vendor_id:, referer:, created_at:)
    id = VendorAnalyticsSourceReferer.find_by(vendor_id: vendor_id, referer: referer).try(:id)

    return id if id.present?

    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, type, referer, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (vendor_id, referer) WHERE referer is not NULL
      DO UPDATE SET vendor_id=EXCLUDED.vendor_id
      RETURNING ID
    }

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              sql,
              vendor_id, name, referer, created_at
            ])

    res = connection.execute query

    res.first['id']
  end
end
