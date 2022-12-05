class VendorJobVkontakte < VendorJob
  def title
    'Выгрузка товаров в группу vkontakte.ru'
  end

  private

  def run
    if vendor.vk_group_id.present?
      vk_exporter = VkontakteExporting::Exporter.new vendor: vendor, group_id: vendor.vk_group_id, inspector: inspector
      vk_exporter.perform
    else
      inspector.details = 'не установлена группа для выгрузки'
    end
  end
end
