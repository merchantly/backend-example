class StockImportingLogEntityRecord < ApplicationRecord
  belongs_to :stock_importing_log_entity, counter_cache: :records_count, foreign_key: :entity_id

  delegate :to_s, to: :message
end
