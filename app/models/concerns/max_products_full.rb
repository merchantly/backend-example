module MaxProductsFull
  extend ActiveSupport::Concern

  included do
    before_create :check_feature_max_products
  end

  private

  def check_feature_max_products
    raise FeatureMaxProductsError if vendor.feature_max_products_full?
  end

  class FeatureMaxProductsError < StandardError; end
end
