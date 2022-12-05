# Модуль предоставляет callback items_updates который
# вызывается при обновлении ProductItem.
#
# Его задача обновить те данные в товаре, которые зависят от его items

module ProductItemsDependency
  def items_updated
    update_ordering!

    update cached_has_items: items.exists?
  end
end
