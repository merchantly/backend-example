module VendorCatalogsGenerate
  def generate_yandex_catalog!
    CatalogGenerator.new(vendor: self).generate_yandex_catalog!
  end

  def generate_torg_mail_catalog!
    CatalogGenerator.new(vendor: self).generate_torg_mail_catalog!
  end

  def generate_facebook_catalog!
    CatalogGenerator.new(vendor: self).generate_facebook_catalog!
  end
end
