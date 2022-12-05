class YandexKassa::MaxCountItemsError < StandardError
  def message
    I18n.vt('errors.order.yandex_kassa_max_items_count', max_count: MaxOrderItemsCountValidation::YANDEX_MAX_ITEMS_COUNT)
  end
end
