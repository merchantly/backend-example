module MoyskladImporting
  module Scheme
    BASIC = [
      MoyskladImporting::WarehouseUpdater,
      MoyskladImporting::DictionaryUpdater,
      MoyskladImporting::DictionaryEntitiesUpdater,
      MoyskladImporting::PropertiesUpdater,
      MoyskladImporting::GoodsUpdater,
      MoyskladImporting::FeaturesUpdater,
      MoyskladImporting::StockUpdater,
      MoyskladImporting::GroupsUpdater
    ].freeze

    FULL = [
      MoyskladImporting::WarehouseUpdater,
      MoyskladImporting::DictionaryUpdater,
      MoyskladImporting::DictionaryEntitiesUpdater,
      MoyskladImporting::PropertiesUpdater,
      MoyskladImporting::GoodFoldersUpdater,
      MoyskladImporting::GoodsUpdater,
      MoyskladImporting::FeaturesUpdater,
      MoyskladImporting::StockUpdater,
      MoyskladImporting::GroupsUpdater
    ].freeze

    SYSTEM = [
      MoyskladImporting::OrganizationsUpdater,
      MoyskladImporting::WarehouseUpdater,
      MoyskladImporting::GroupsUpdater
    ].freeze
  end
end
