module CategoryCountersService
  class UpdateCounters
    include Virtus.model

    attribute :categories, Array[Category], required: true
    attribute :with_children, Boolean, default: false

    COUNTERS = %w[products published_products active_products
                  deep_products deep_published_products deep_published_and_ordering_products deep_active_products ]
               .map { |c| "#{c}_count" }

    attr_accessor :updated_category_ids

    def call
      return if Thread.current[STRATEGY_NAME] == Strategies::DISABLE

      self.updated_category_ids = Set.new
      deep_update_categories_counters
    end

    # для запуска как sidekiq воркера
    def self.call(category_ids:, with_children: false)
      new(categories: Category.where(id: category_ids), with_children: with_children).call
    end

    private

    def deep_update_categories_counters
      categories.each do |category|
        if Thread.current[STRATEGY_NAME] == Strategies::ATOMIC
          Thread.current[WILL_UPDATE_CATEGORIES] << category.id
          next
        end
        update_category_counters(category)
        update_parent_categories_counters(category)
        update_children_categories_counters(category) if with_children
      end
    end

    def update_parent_categories_counters(category)
      parent_category = category.parent
      return if parent_category.blank?

      update_category_counters(parent_category)
      update_parent_categories_counters(parent_category)

      # При удалении вендора запросто может всплыть
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn e
    end

    def update_children_categories_counters(category)
      scope = category.children.alive
      return unless scope.any?

      scope.find_each do |children_category|
        update_category_counters(children_category)
        update_children_categories_counters(children_category)
      end
    end

    def update_category_counters(category)
      return if updated_category_ids.include?(category.id)

      columns = { updated_at: Time.zone.now }

      COUNTERS.each do |counter|
        columns[counter] = get_counter(counter, category)
      end

      category.update_columns columns unless category.destroyed?

      updated_category_ids << category.id
    end

    def get_counter(counter, category)
      send "get_#{counter}", category
    end

    def get_products_count(category)
      Product.common.by_category(category).distinct.count
    end

    def get_published_products_count(category)
      Product.common.by_category(category).published.distinct.count
    end

    def get_active_products_count(category)
      Product.common.by_category(category).active.distinct.count
    end

    def get_deep_products_count(category)
      Product.common.by_deep_categories(category).distinct.count
    end

    def get_deep_published_products_count(category)
      Product.common.by_deep_categories(category).published.distinct.count
    end

    def get_deep_published_and_ordering_products_count(category)
      Product.common.by_deep_categories(category).published.distinct.select(&:has_ordering_goods).count
    end

    def get_deep_active_products_count(category)
      Product.common.by_deep_categories(category).active.distinct.count
    end
  end
end
