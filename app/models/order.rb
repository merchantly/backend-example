class Order < ApplicationRecord
  # Устанавливается при выполнении комманды для того, в колбеках иметь
  # автора изменений (например указать аватора при изменении статуса заказа в комментарии)
  attr_accessor :author

  include RoutesConcern
  include Authority::Abilities
  include Archivable
  include TimeScopes
  include HasAdminComments
  include PhoneAndEmail
  include CurrentVendor
  include OrderStates # WorkflowState
  include OrderWalletone
  include OrderUrls
  include OrderReservation
  include OrderPrice
  include OrderDeliverySupport
  include OrderLogEntities
  include OrderCallbacks
  include OrderValidations
  include OrderAmoCRM
  include OrderCartItems
  include OrderCommerceMl
  include PgSearch::Model
  include OrderSource
  include OrderRefund
  include OrderWarehouseIssue

  belongs_to :vendor
  belongs_to :coupon
  belongs_to :delivery_city
  belongs_to :pickup_point, class_name: 'DeliveryPickupPoint'
  belongs_to :payment_type, class_name: 'VendorPayment'
  belongs_to :package_good, polymorphic: true
  belongs_to :cart
  belongs_to :client
  belongs_to :delivery_time_period
  belongs_to :yandex_delivery, class_name: 'YandexDelivery::Delivery'
  belongs_to :cdek_delivery, class_name: 'Cdek::Delivery'
  belongs_to :member

  has_many :client_last_order, through: :client, source: :last_order, dependent: :nullify
  has_many :client_first_order, through: :client, source: :first_order, dependent: :nullify
  has_many :items, dependent: :destroy, class_name: 'OrderItem', autosave: true
  has_many :order_condition_orders, dependent: :destroy

  has_many :ecr_documents, class_name: 'Ecr::Document'
  has_one :sale_document, class_name: 'Ecr::SaleDocument'
  has_many :refund_documents, class_name: 'Ecr::RefundDocument'
  has_many :refund_order_items, class_name: 'Ecr::RefundOrderItem'

  has_one :order_payment, dependent: :delete
  has_one :order_remote_stock, dependent: :delete
  has_one :order_local_stock, dependent: :delete

  validates :transaction_id, uniqueness: { allow_blank: true }
  validates :uuid, uniqueness: { allow_blank: true }
  validates :tid, numericality: { only_integer: true }, length: { maximum: Settings.tid_max_length, minimum: Settings.tid_min_length }, allow_blank: true

  before_validation :set_tid

  counter_culture :client
  counter_culture :vendor

  pg_search_scope :by_query,
                  against: %i[id name phone email address],
                  associated_against: {
                    order_delivery: :external_id,
                    items: :title_translations
                  },
                  using: {
                    tsearch: { dictionary: 'russian' }
                  }

  scope :by_client, ->(client) { where client: client }
  scope :by_reserve, ->(flag) { joins(:order_local_stock).where order_local_stocks: { is_reserved: flag } }
  scope :by_coupon_code, ->(code) { where(coupon_code: code.to_s.upcase) }
  scope :ordered, -> { order id: :desc }
  scope :by_created_at, ->(beginning_of_month, end_of_month) { where('orders.created_at >= ? AND orders.created_at <= ?', beginning_of_month, end_of_month) }
  scope :with_includes, -> { includes(:order_payment, :order_remote_stock, :order_local_stock, :items) }
  scope :by_address, ->(address) { where address: address }
  scope :by_week, ->(date) { where 'created_at >= ? and created_at <= ?', date.beginning_of_week, date.end_of_week }
  scope :payed, -> { joins(:order_payment).where(order_payments: { state: :paid }) }
  scope :by_payment_key, ->(payment_key) { joins(:payment_type).where(vendor_payments: { payment_key: payment_key }) }

  serialize :ms_order_dump

  accepts_nested_attributes_for :items, allow_destroy: true
  accepts_nested_attributes_for :order_payment, reject_if: :all_blank

  before_create :generate_slug
  before_create do
    # TODO use locale of user
    self.locale ||= vendor.default_locale
  end

  after_create :create_payment!
  after_create :create_stocks!

  after_create do
    attrs = [:last_order_at]
    attrs << :last_success_order_at if success?
    vendor.touch(*attrs)
  end

  after_commit :update_client_counters, on: %i[create update]

  after_update if: :success? do
    vendor.touch :last_success_order_at
  end

  before_create do
    set_ip_location
  end

  delegate :need_delivery?, to: :order_delivery
  delegate :payment_key, to: :payment_type

  def weight
    items.map(&:item_weight).compact.sum
  end

  def possible_order_conditions
    @possible_order_conditions ||= vendor
                                   .order_conditions
                                   .alive
                                   .with_workflow_state(workflow_state)
                                   .with_vendor_delivery(delivery_type)
                                   .with_vendor_payment(payment_type)
                                   .with_order_payment_state(order_payment.state)
                                   .with_order_delivery_state(order_delivery.state)
  end

  def country
    Bugsnag.notify 'Requested counter' do |b|
      b.meta_data = { order_id: id }
    end
    'Россия'
  end

  def full_address
    @full_address ||= [city_to_delivery, address].compact.join(', ')
  end

  def full_name
    @full_name ||= (name.presence || [second_name, first_name, patronymic].join(' '))
  end

  def city_to_delivery
    if delivery_city.present?
      delivery_city.title
    elsif city_title.present?
      city_title
    else
      delivery_type.city_title
    end
  end

  def address_to_delivery
    if pickup_point.present?
      pickup_point.title
    else
      address
    end
  end

  def invoice_title
    I18n.vt 'order.title', number: public_id, vendor: vendor.active_domain
  end

  def public_invoice_url
    return unless order_payment.is_a? OrderPaymentInvoice

    "#{public_url}/invoice.pdf"
  end

  def title
    local_id.to_s
  end

  def public_id
    external_id
  end

  def to_s
    title
  end

  # TODO не светить порядок в будущем
  def local_id
    id.to_s
  end

  def description
    items.map(&:long_title).join(', ')
  end

  def goods_quantity
    items.sum(&:quantity)
  end

  def currency
    Money::Currency.find currency_iso_code || vendor.default_currency
  end

  def zero_money
    Money.new 0, currency
  end

  def products
    items.map(&:product).compact
  end

  def has_misc_info?
    ip? || ip_location? || user_agent?
  end

  def commands(author = nil)
    @commands_handlers ||= {}
    @commands_handlers[author] ||= OrderCommands::Handler.new self, author
  end

  def run_out_goods
    @run_out_goods ||= items.map(&:good).compact.select(&:is_run_out)
  end

  def dimension
    # TODO Считать объем исходя из пунктов заказа
    Dimension.new.freeze
  end

  def package_good_global_id
    return if package_good.blank?

    package_good.global_id
  end

  def free?
    total_with_delivery_price.to_f.zero?
  end

  def custom_delivery_price?
    delivery_type.price.nil? && !delivery_type.is_cdek_delivery?
  end

  private

  def set_tid
    self.tid = ZeroAdder.perform(tid, Settings.tid_max_length) if tid.present?
  end

  def set_ip_location
    return if ip.blank?

    location = GeoIP_City.city ip
    self.ip_location = [location.country_name, location.real_region_name, location.city_name].join(', ') if location.present?
  rescue SocketError # Корявый адрес ip
    nil
  end

  def create_stocks!
    # TODO Асинхронно?
    create_order_remote_stock!
    create_order_local_stock!
  end

  def create_payment!
    payment_type.agent_class.create! order_id: id
  end

  def generate_slug
    self.slug = SecureRandom.urlsafe_base64
  end

  def update_client_counters
    ClientCountersUpdater.perform_async(client_id) if client_id.present?
  end
end
