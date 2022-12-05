module VendorDestroy
  def self.destroing?(id)
    Thread.current[:destroy_vendor_id] == id
  end

  def destroy(force = (Rails.env.test? || Rails.env.development?))
    Thread.current[:destroy_vendor_id] = id
    $ignore_fail_destroy_root = true

    super() if force
  ensure
    $ignore_fail_destroy_root = false
    Thread.current[:destroy_vendor_id] = nil
  end
end
