class Settings < Settingslogic
  source Rails.root.join('config/application.local.yml') if File.exist? Rails.root.join('config/application.local.yml')
  source Rails.root.join('config/application.yml')
  namespace Rails.env

  suppress_errors Rails.env.production?

  ActionDispatch::Http::URL.tld_length = Settings.tld_length

  def root
    Pathname.new(super.presence || Rails.root)
  end
  SYSTEM_SUBDOMAIN = ''.freeze
end

require 'socket'
Settings['hostname'] = Socket.gethostname

class Settings::Currencies < Settingslogic
  source Rails.root.join('config/settings/currencies.local.yml') if File.exist? Rails.root.join('config/settings/currencies.local.yml')
  source Rails.root.join('config/settings/currencies.yml')

  def all
    currencies.map do |iso_num|
      Money::Currency.find_by_iso_numeric iso_num
    end
  end
end

class Settings::Billing < Settingslogic
  source Rails.root.join('config/settings/billing.yml')
end

class Settings::Themes < Settingslogic
  source Rails.root.join('config/settings/themes.yml')
end

class Settings::Elasticsearch < Settingslogic
  source Rails.env.test? ? Rails.root.join('config/settings/elasticsearch.test.yml') : Rails.root.join('config/settings/elasticsearch.yml')
end

class Settings::SMSPacks < Settingslogic
  source Rails.root.join('config/settings/sms_packs.yml')
end

class Settings::Taxes < Settingslogic
  source Rails.root.join('config/settings/taxes.local.yml') if File.exist? Rails.root.join('config/settings/taxes.local.yml')
  source Rails.root.join('config/settings/taxes.yml')
end

class Settings::Brand < Settingslogic
  source Rails.root.join('config/settings/brand.local.yml') if File.exist? Rails.root.join('config/settings/brand.local.yml')
  source Rails.root.join('config/settings/brand.yml')

  def t(key)
    Settings::Brand[I18n.locale][key.to_s] || "No key '#{key}' for Settings::Brand #{I18n.locale}"
  end
end

class Settings::Help < Settingslogic
  source Rails.root.join('config/settings/help.local.yml') if File.exist? Rails.root.join('config/settings/help.local.yml')

  source Rails.root.join('config/settings/help.yml')
end

class Settings::Metrics < Settingslogic
  source Rails.root.join('config/settings/metrics.yml')
end

class Settings::Bells < Settingslogic
  source Rails.root.join('config/settings/bells.yml')
end

class Settings::Integrations < Settingslogic
  source Rails.root.join('config/settings/integrations.yml')
end

class Settings::Order < Settingslogic
  source Rails.root.join('config/settings/order.yml')
end

class Settings::TimeZone < Settingslogic
  source Rails.root.join('config/settings/time_zone.yml')
end

class Settings::Logger < Settingslogic
  source Rails.root.join('config/settings/logger.local.yml') if File.exist? Rails.root.join('config/settings/logger.local.yml')

  source Rails.root.join('config/settings/logger.yml')
end

class Settings::Features < Settingslogic
  source Rails.root.join('config/settings/features.local.yml') if File.exist? Rails.root.join('config/settings/features.local.yml')

  source Rails.root.join('config/settings/features.yml')
end

class Settings::WidgetPaths < Settingslogic
  source Rails.root.join('config/settings/widget_paths.yml')
end

class Settings::DefaultVats < Settingslogic
  source Rails.root.join('config/settings/default_vats.yml')
end
