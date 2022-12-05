class CacheKeyGenerator
  def self.perform(record, attrs)
    timestamp = attrs.map { |attr| record.send(attr) }.compact.map(&:to_time).max

    "#{record.model_name.cache_key}/#{record.id}-#{timestamp}"
  end
end
