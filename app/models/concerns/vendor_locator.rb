module VendorLocator
  def locate(global_id)
    entity = GlobalID::Locator.locate global_id

    raise Error, "Entity with #{global_id} for vendor #{id} is not found" if entity.blank?

    raise Error, "Entity #{global_id} does not belongs to vendor #{id} (#{entity.vendor_id})!" unless entity.vendor_id == id

    entity
  end

  def locate_good(global_id)
    good = locate global_id
    raise Error, "The good #{good} with #{global_id} has wrong type #{good.class} for vendor #{id}" unless [ProductUnion, Product, ProductItem].include? good.class

    good
  end

  def locate_package(global_id)
    package = locate_good global_id
    raise Error, "The entity #{package} with #{global_id} is not package for vendor #{id}" unless package.is_package?

    package
  end

  class Error < StandardError; end
end
