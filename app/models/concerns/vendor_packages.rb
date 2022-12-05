module VendorPackages
  extend ActiveSupport::Concern

  included do
    after_save :update_packages, if: :saved_change_to_package_category_id?
    validate :welcome_category_package_category_not_same
  end

  def has_packages?
    package_category.present?
  end

  def packages
    return Product.none unless has_packages?

    package_category.products.alive.published.good_ordering
  end

  private

  def welcome_category_package_category_not_same
    if package_category_id.present? && package_category_id == welcome_category_id
      errors.add(:package_category_id, I18n.t('validators.vendor.welcome_category_package_category_not_same'))
      errors.add(:welcome_category_id, I18n.t('validators.vendor.welcome_category_package_category_not_same'))
    end
  end

  def update_packages
    products.by_category_id(package_category_id_was).update_all cached_is_package: false if package_category_id_was.present?
    products.by_category_id(package_category_id).update_all cached_is_package: true if package_category_id.present?
  end
end
