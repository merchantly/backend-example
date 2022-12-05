module VendorRobots
  extend ActiveSupport::Concern

  included do
    after_create :create_default_robots
    after_update :update_robots_host, if: :host_changed?
  end

  def robots
    @robots ||= VendorRobotsResource.new(vendor: self).get
  end

  def robots=(value)
    @robots = value
  end

  def create_default_robots
    return if is_pre_create || !is_published

    VendorRobotsEditor.new(vendor: self).set_defaults
  end

  private

  def host_changed?
    (domain.blank? && (saved_change_to_subdomain? && subdomain_was.present?)) || saved_change_to_domain? || saved_change_to_https_custom_domain?
  end

  def update_robots_host
    VendorRobotsEditor.new(vendor: self).update_host
  end
end
