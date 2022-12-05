module CategoryCounters
  extend ActiveSupport::Concern
  included do
    after_commit :update_category_counters
  end

  private

  def update_category_counters
    update_categories = [self]
    update_categories += vendor.categories.where(id: ancestry_was.split('/')).to_a if ancestry_was.present?

    CategoryCountersService::UpdateCounters.new(categories: update_categories).call
  end
end
