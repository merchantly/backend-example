# Source
# http://stackoverflow.com/questions/5490411/counting-the-number-of-queries-performed

require 'active_record/query_counter'

RSpec::Matchers.define :exceed_query_limit do |expected|
  supports_block_expectations

  match do |block|
    query_count(&block) > expected
  end

  failure_message_when_negated do |_actual|
    "Expected to run maximum #{expected} queries, got #{@counter.query_count}"
  end

  def query_count(&block)
    @counter = ActiveRecord::QueryCounter.new
    ActiveSupport::Notifications.subscribed(@counter.method(:call), 'sql.active_record', &block)
    @counter.query_count
  end
end
