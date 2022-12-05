module SimilarProducts
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    after_destroy :delete_from_similar

    enumerize :show_similar_products, in: %w[auto selected_only off], default: ->(product) { product.vendor.default_similar_products_mode }
    enumerize :show_other_products, in: %w[auto selected_only off], default: 'selected_only'

    scope :by_similar_id, ->(id) { where '? = ANY(similar_products_ids)', id }
    scope :by_other_id, ->(id) { where '? = ANY(other_products_ids)', id }
  end

  def similar_products=(products)
    self.similar_products_ids = [products].flatten.map(&:id)
  end

  def other_products=(products)
    self.other_products_ids = [products].flatten.map(&:id)
  end

  def similar_products
    return Product.none if similar_products_ids.blank?

    vendor.products.where id: similar_products_ids
  end

  def other_products
    return Product.none if other_products_ids.blank?

    vendor.products.where id: other_products_ids
  end

  def similar_products_ids=(ids)
    super (ids - [id]).uniq
  end

  def other_products_ids=(ids)
    super (ids - [id]).uniq
  end

  private

  def delete_from_similar
    Product.by_similar_id(id).update_all ['similar_products_ids = array_remove(similar_products_ids, ?)', id]
    Product.by_similar_id(id).update_all ['other_products_ids = array_remove(other_products_ids, ?)', id]
  end
end
