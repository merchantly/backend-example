class VendorAnalyticsSourceUtm < VendorAnalyticsSource
  validates :utm_entity, presence: true

  def utm_entity
    UtmEntity.build_from_params attributes
  end

  def self.safe_create(vendor_id:, utm:, created_at:)
    attrs = utm.to_h.compact

    raise 'Не могу создать SourceUtm без utm значений' if attrs.empty?

    attrs[:vendor_id] = vendor_id

    id = VendorAnalyticsSourceUtm.find_by(attrs).try(:id)

    return id if id.present?

    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, type, utm_source, utm_campaign, utm_medium, utm_term, utm_content, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (vendor_id, utm_source, utm_campaign, utm_medium, utm_term, utm_content) WHERE referer is NULL
      DO UPDATE SET vendor_id=EXCLUDED.vendor_id
      RETURNING ID
    }

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              sql,
              vendor_id, name, utm.utm_source, utm.utm_campaign, utm.utm_medium, utm.utm_term, utm.utm_content, created_at
            ])

    res = connection.execute query

    res.first['id']
  end
end
