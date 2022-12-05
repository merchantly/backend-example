class VendorAmoCrm < ApplicationRecord
  NoCredentials = Class.new StandardError
  belongs_to :vendor

  validates :login, presence: true, if: :is_active?
  validates :apikey, presence: true, if: :is_active?
  validates :url, presence: true, url: { allow_blank: true }, if: :is_active?

  validates :goods_catalog_id, presence: true, if: :enable_goods_linking?
  validates :goods_catalog_moysklad_custom_field_id, presence: true, if: :enable_goods_linking?

  validates :is_active, inclusion: { in: [true, false] }
  validates :enable_goods_linking, inclusion: { in: [true, false] }
  validates :enable_sale_not_linked, inclusion: { in: [true, false] }

  validate :test_auth, if: :is_active?

  delegate :client, to: :universe

  # TODO пересохранять товары при изменении enable_sale_not_linked и enable_goods_linking

  def import_goods!
    System::AmoCRM::GoodsImporter
      .new(vendor: vendor, catalog_id: goods_catalog_id, moysklad_custom_field_id: goods_catalog_moysklad_custom_field_id)
      .perform
  end

  def export_goods!
    System::AmoCRM::ExportProducts
      .new(vendor: vendor, catalog_id: goods_catalog_id, moysklad_custom_field_id: goods_catalog_moysklad_custom_field_id, products: vendor.products.common.alive)
      .perform
  end

  def account
    @account ||= client.get('accounts/current')['account']
  end

  def universe
    @universe ||= ::AmoCRM::Universe.build(
      user_login: login,
      user_hash: apikey,
      url: url
    )
  end

  def test_auth!
    # Так как в процессе build-а проверяется клиентская авторизация, нам этого достаточно
    raise NoCredentials, 'Не все параметры для доступа к API AmoCRM указаны (login,hash,url)' unless login.present? && apikey.present? && url.present?

    client.get 'accounts/current'
  end

  def test_auth
    test_auth!
  rescue StandardError => e
    Bugsnag.notify e
    errors.add :base, e.to_s
    false
  end
end
