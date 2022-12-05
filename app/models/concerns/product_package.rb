module ProductPackage
  def is_package?
    vendor.package_category_id.present? && category_ids.include?(vendor.package_category_id)
  end

  alias is_package is_package?
end
