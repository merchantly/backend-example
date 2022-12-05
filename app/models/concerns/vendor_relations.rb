module VendorRelations
  extend ActiveSupport::Concern

  included do
    has_one :theme, class_name: 'VendorTheme'
    has_one :vendor_rfm, dependent: :destroy
    has_one :top_banner, dependent: :destroy

    has_one :vendor_amocrm, class_name: 'VendorAmoCrm'
    accepts_nested_attributes_for :vendor_amocrm, reject_if: :all_blank

    has_one :vendor_bitrix24, class_name: 'VendorBitrix24'
    accepts_nested_attributes_for :vendor_bitrix24, reject_if: :all_blank

    belongs_to :public_offer_page, -> { where is_active: true }, class_name: 'ContentPage'
    belongs_to :manager, class_name: 'AdminUser'
    belongs_to :partner_coupon, class_name: '::Partner::Coupon'
    has_one :partner, through: :partner_coupon, class_name: '::Partner'

    belongs_to :order_warehouse, class_name: 'Warehouse'
    belongs_to :vendor_template, class_name: 'VendorTemplate'
    belongs_to :source_vendor, class_name: 'Vendor'

    has_many :text_blocks,                  dependent: :delete_all
    has_many :vendor_exchange_rates,        dependent: :delete_all
    has_many :import_spread_sheet_infos,    dependent: :delete_all, class_name: '::ImportSpreadSheetInfo'
    has_many :stock_importing_log_entities, dependent: :destroy
    has_many :order_conditions,             dependent: :delete_all, class_name: '::OrderCondition'
    has_many :workflow_states,              dependent: :delete_all, class_name: '::WorkflowState'
    has_many :menu_items,                   dependent: :destroy
    has_many :vendor_jobs,                  dependent: :delete_all
    has_many :product_unions
    has_many :products, dependent: :destroy
    has_many :product_prices
    has_many :product_images, dependent: :destroy
    has_many :product_items # Удаляются через products
    has_many :slugs, dependent: :delete_all
    has_many :slug_redirects
    has_many :slug_resources
    has_many :history_paths,                dependent: :delete_all
    has_many :asset_images,                 dependent: :destroy
    has_many :selling_currencies,           dependent: :delete_all, class_name: 'VendorSellingCurrency'
    has_many :order_fields,                 dependent: :delete_all, class_name: 'VendorOrderField'

    has_many :categories,                   dependent: :destroy

    has_many :vendor_sms_incomes,           dependent: :delete_all
    has_many :bank_incoming_contractors,    dependent: :delete_all

    has_many :vendor_organizations,         dependent: :delete_all
    belongs_to :vendor_organization

    has_many :carts,                        dependent: :destroy
    has_many :authentications,              dependent: :destroy, as: :authenticatable
    has_many :invites,                      dependent: :destroy
    has_many :wishlists,                    dependent: :destroy

    has_many :members,                      dependent: :destroy
    has_many :owners,                       -> { joins(:role).where roles: { key: Role::OWNER } }, class_name: 'Member'
    has_many :orders,                       dependent: :destroy
    has_many :done_orders,                  class_name: 'Order'
    has_many :order_items,                  through: :orders, source: :items
    has_many :clients,                      dependent: :destroy

    has_many :coupons,                      dependent: :destroy
    has_many :coupon_singles
    has_many :coupon_groups
    has_many :promotions

    has_many :dictionaries,                 dependent: :destroy
    has_many :dictionary_entities,          dependent: :destroy
    has_many :translations,                 dependent: :destroy

    has_many :slider_images,    dependent: :destroy
    has_many :lookbooks,        dependent: :destroy
    has_many :content_pages,    dependent: :destroy
    has_many :blog_posts,       dependent: :destroy

    has_many :mail_templates, dependent: :destroy

    has_many :payment_accounts
    has_many :openbill_charges, through: :payment_accounts
    has_many :vendor_sms_log_entities, dependent: :delete_all
    has_many :order_operator_filters, dependent: :destroy

    has_many :subscription_emails, dependent: :delete_all
    has_many :roles, dependent: :destroy

    has_many :tags, dependent: :destroy

    has_one :vendor_email, dependent: :delete

    has_one :commerce_ml_configuration, class_name: 'CommerceML::Configuration'

    has_many :coupon_images, dependent: :destroy

    has_many :vendor_groups
    belongs_to :vendor_group

    has_many :order_payments, through: :orders

    has_many :branches, dependent: :destroy, class_name: 'Ecr::Branch'
    has_many :cashiers, dependent: :destroy, class_name: 'Ecr::Cashier'
    has_many :documents, dependent: :destroy, class_name: 'Ecr::Document'

    has_many :daily_cashier_reports, through: :cashiers, source: :daily_reports
    has_many :daily_total_reports, class_name: 'Ecr::DailyTotalReport'

    belongs_to :default_branch, class_name: 'Ecr::Branch'
    belongs_to :default_cashier, class_name: 'Ecr::Cashier'
    belongs_to :default_warehouse, class_name: 'Warehouse'

    has_many :product_vat_groups, dependent: :destroy
    belongs_to :default_product_vat_group, class_name: 'ProductVatGroup'

    has_many :vendor_analytics_visits, dependent: :destroy
    has_many :vendor_analytics_days, dependent: :destroy
    has_many :vendor_analytics_session_products, dependent: :destroy
    has_many :vendor_analytics_sources, dependent: :destroy
    has_many :vendor_analytics_visit_to_sources, dependent: :destroy
    has_many :vendor_analytics_visitor_events, dependent: :destroy
    has_many :vendor_analytics_visitors, dependent: :destroy

    has_many :external_devices, dependent: :destroy

    has_many :warehouses, dependent: :destroy
    has_many :warehouse_cells, through: :warehouses, source: :nomenclatures
    has_many :warehouse_movements, class_name: 'Ecr::WarehouseMovement'

    has_many :nomenclatures, class_name: 'Ecr::Nomenclature'

    has_many :drawers, class_name: 'Ecr::Drawer'
  end
end
