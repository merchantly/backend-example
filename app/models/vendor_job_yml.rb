class VendorJobYML < VendorJob
  validates :asset, presence: true

  def title
    'Загрузка YML-каталога'
  end

  private

  def run
    YMLCatalog::Import
      .new(vendor: vendor, body: file.get.body, inspector: inspector)
      .perform
  end
end
