module RecommendedProducts
  extend ActiveSupport::Concern

  included do
    before_validation do
      if recommended_products_ids.present?
        self.recommended_products_ids = Vendor.find(vendor_id).products.where(id: recommended_products_ids.compact.uniq).pluck(:id).sort
      end
    end
  end

  def recommended_products
    return Product.none if recommended_products_ids.blank?

    Vendor.find(vendor_id).products.where id: recommended_products_ids
  end
end
