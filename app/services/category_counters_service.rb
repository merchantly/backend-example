# Use example:
# CategoryCountersService.strategy(CategoryCountersService::Strategies::ATOMIC) do
#    products.find_each(&:save)
# end

module CategoryCountersService
  STRATEGY_NAME = :category_counters_strategy
  WILL_UPDATE_CATEGORIES = :category_counters_will_update_categories

  def self.strategy(name, is_sidekiq: false, &block)
    if Thread.current[STRATEGY_NAME].present? || Thread.current[WILL_UPDATE_CATEGORIES].present?
      Bugsnag.notify 'CategoryCountersService strategy present', metaData: {
        strategy_name: Thread.current[STRATEGY_NAME],
        will_update_categories: Thread.current[WILL_UPDATE_CATEGORIES]
      }
    end

    Thread.current[STRATEGY_NAME] = name
    Thread.current[WILL_UPDATE_CATEGORIES] = Set.new

    block.call
  ensure
    will_update_categories = Thread.current[WILL_UPDATE_CATEGORIES].to_a
    strategy_name = Thread.current[STRATEGY_NAME]

    Thread.current[STRATEGY_NAME] = nil
    Thread.current[WILL_UPDATE_CATEGORIES] = nil

    if strategy_name == Strategies::ATOMIC && will_update_categories.present? && !will_update_categories.count.zero?
      if is_sidekiq
        CategoryCountersService::UpdateCounters.call(category_ids: will_update_categories)
      else
        CategoryCountersService::UpdateCounters.new(
          categories: Category.where(id: will_update_categories)
        ).call
      end
    end
  end

  module Strategies
    DEFAULT = :default
    ATOMIC = :atomic
    DISABLE = :disable
  end
end
