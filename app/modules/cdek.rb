module Cdek
  EXPRESS_D_W_TARIFF = 12
  EXPRESS_D_D_TARIFF = 1

  W_W_TARIFF = 136
  W_D_TARIFF = 137
  D_W_TARIFF = 138

  HOME_TARIFFS = [EXPRESS_D_D_TARIFF, W_D_TARIFF].freeze
  PICKUP_POINT_TARIFFS = [EXPRESS_D_W_TARIFF, W_W_TARIFF, D_W_TARIFF].freeze

  REQUIRED_AUTH_TARIFFS = [W_W_TARIFF, W_D_TARIFF].freeze

  TARIFFS = [
    ["(#{EXPRESS_D_D_TARIFF}) Экспресс лайт дверь-дверь", EXPRESS_D_D_TARIFF],
    ["(#{EXPRESS_D_W_TARIFF}) Экспресс лайт дверь-склад", EXPRESS_D_W_TARIFF],
    ["(#{W_W_TARIFF}) Посылка склад-склад", W_W_TARIFF],
    ["(#{W_D_TARIFF}) Посылка склад-дверь", W_D_TARIFF],
    ["(#{D_W_TARIFF}) Посылка дверь-склад", D_W_TARIFF]
  ].freeze
end
