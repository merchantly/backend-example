module OrderSource
  extend ActiveSupport::Concern

  SOURCE_ONLINE = 'online'.freeze
  SOURCE_OFFLINE = 'offline'.freeze
  SOURCES = [SOURCE_OFFLINE, SOURCE_ONLINE].freeze

  included do
    extend Enumerize

    enumerize :source, in: OrderSource::SOURCES, default: OrderSource::SOURCE_ONLINE, scope: true
  end
end
