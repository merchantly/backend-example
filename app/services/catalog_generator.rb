class CatalogGenerator
  include Virtus.model

  attribute :vendor, Vendor

  YANDEX_CATALOG_FILE = 'yandex_catalog.xml'.freeze

  TORG_MAIL_FILE = 'tmail_catalog.xml'.freeze

  FACEBOOK_CATALOG_FILE = 'facebook_catalog.csv'.freeze

  YANDEX_TURBO_PAGES_FILE = 'turbo_pages.xml'.freeze

  def generate_yandex_catalog!
    xml = Export::YandexMarket::Yml.new(vendor).generate.to_xml
    file = write_file(YANDEX_CATALOG_FILE, xml)
    vendor.update yandex_catalog: file
    delete_file(YANDEX_CATALOG_FILE)
  end

  def generate_torg_mail_catalog!
    xml = Export::TorgMail::Yml.new(vendor).generate.to_xml
    file = write_file(TORG_MAIL_FILE, xml)
    vendor.update torg_mail_catalog: file
    delete_file(TORG_MAIL_FILE)
  end

  def generate_facebook_catalog!
    csv = Export::FacebookCatalog::Csv.new(vendor: vendor).generate
    file = write_file(FACEBOOK_CATALOG_FILE, csv)
    vendor.update facebook_catalog: file
    delete_file(FACEBOOK_CATALOG_FILE)
  end

  def generate_yandex_turbo_pages!
    xml = ExportYandexTurbo.new(vendor).call.to_xml
    file = write_file(YANDEX_TURBO_PAGES_FILE, xml)
    vendor.update yandex_turbo_pages: file
    delete_file(YANDEX_TURBO_PAGES_FILE)
  end

  private

  def write_file(filename, data)
    FileUtils.mkdir_p(tmp_path)
    File.write(tmp_path.join(filename), data)
    File.new tmp_path.join(filename)
  end

  def delete_file(filename)
    FileUtils.rm tmp_path.join(filename), force: true
  end

  def tmp_path
    Rails.root.join "tmp/catalog/#{vendor.id}/"
  end
end
