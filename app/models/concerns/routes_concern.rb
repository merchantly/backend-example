module RoutesConcern
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def default_url_options(options = {})
    vendor = Thread.current[:vendor]
    options.merge locale: (vendor.present? && I18n.locale.to_s != vendor.default_locale ? I18n.locale : nil)
  end
end
