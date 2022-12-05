module Categorizable
  extend ActiveSupport::Concern

  included do
    scope :empty_categories, lambda {
      joins('LEFT OUTER JOIN category_products ON category_products.product_id = products.id').where(category_products: { id: nil })
    }
    scope :not_empty_categories, lambda {
      joins(:category_products).distinct
    }
    scope :by_category_id, ->(id) { joins(:category_products).where(category_products: { category_id: id }) }

    scope :by_category, lambda { |category|
      if category.persisted?
        by_category_id(category.id).where vendor_id: category.vendor_id
      else
        where(vendor_id: category.vendor_id).empty_categories
      end
    }
    scope :by_deep_categories, lambda { |category|
      if category.persisted?
        joins(:category_products).where(category_products: { category_id: category.subtree_ids }).where(vendor_id: category.vendor_id)
      else
        empty_categories
      end
    }

    scope :by_categories_ids, ->(categories_ids) { joins(:category_products).where(category_products: { category_id: categories_ids }) }
    scope :exclude_by_categories, ->(categories_ids) { joins(:category_products).where.not(category_products: { category_id: categories_ids }) }

    after_commit :update_categories_counters
  end

  def category
    main_category
  end

  def category_id
    main_category_id
  end

  def category=(new_category)
    self.category_id = new_category.try(:id)
  end

  def category_id=(new_category_id)
    old_category_id = category_id
    self.main_category_id = new_category_id
    ids = category_ids.clone
    ids << new_category_id if new_category_id.present?
    ids << old_category_id if old_category_id.present? && new_category_id != old_category_id
    self.category_ids = ids
  end

  def category_ids=(new_ids)
    ids = Array(new_ids).compact.uniq
    self.cached_category_ids = ids
    super ids
  end

  def categories_path_ids
    categories.map(&:path_ids).flatten
  end

  private

  def update_categories_counters
    categories = Category.where(id: previous_changes['cached_category_ids'].to_a.flatten.uniq)
    CategoryCountersService::UpdateCounters.new(categories: categories).call
  end
end
