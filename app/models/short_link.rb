class ShortLink < ApplicationRecord
  SLUG_LENGTH = 6
  CHARSET = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a

  SHORT_URL_PREFIX = 'https://kiiiosk.store/s/'.freeze

  def self.generate(url)
    slug = generate_unique_key

    query = ApplicationRecord
      .send(:sanitize_sql_array,
            [
              "INSERT INTO #{table_name} (url, slug, created_at) VALUES (?, ?, ?) ON CONFLICT (url) DO UPDATE SET url=EXCLUDED.url RETURNING slug",
              url, slug, Time.zone.now
            ])

    res = connection.execute query
    # Если был insert, то res.result_status == 2
    #
    # Если был уникальный url, то res.values == [["P5ifPy"]]
    SHORT_URL_PREFIX + res.values.first.first
  end

  def self.generate_unique_key
    (0...SLUG_LENGTH).map { CHARSET[rand(CHARSET.size)] }.join
  end

  def to_param
    slug
  end
end
