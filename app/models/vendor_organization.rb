class VendorOrganization < ApplicationRecord
  include MoyskladEntity
  include Archivable

  def to_s
    name
  end

  def name
    buffer = super

    buffer << ' (в архиве)' if archived?
    buffer
  end
end
