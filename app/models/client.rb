require 'securerandom'

class Client < ApplicationRecord
  include Authority::Abilities
  include Archivable
  include SeparatedList
  include HasAdminComments
  include MoyskladEntity
  include ClientNotification
  include ClientScopes

  REQUEST_TIMEOUT = Rails.env.development? ? 10.seconds : 60.seconds
  HOUSE_REGEXP = OrderValidations::HOUSE_REGEXP # 5, 5A, 5а

  SESSION_KEY = :client_id

  belongs_to :vendor, counter_cache: true
  belongs_to :last_order, class_name: 'Order'
  belongs_to :first_order, class_name: 'Order'

  has_one :wishlist, dependent: :nullify

  has_many :orders, dependent: :destroy
  has_many :order_items, through: :orders, source: :items
  has_many :phones, class_name: 'ClientPhone', dependent: :delete_all
  has_many :emails, class_name: 'ClientEmail', dependent: :delete_all

  belongs_to :occupation, class_name: 'ClientOccupation'

  belongs_to :client_category

  strip_attributes only: %i[address city_title area street name], collapse_spaces: true

  monetize :total_orders_price_cents, as: :total_orders_price
  monetize :average_orders_price_cents, as: :average_orders_price
  monetize :customer_balance_cents, as: :customer_balance

  before_create do
    self.total_orders_price = vendor.zero_money
    self.average_orders_price = vendor.zero_money
    self.customer_balance = vendor.zero_money
  end

  validates :name, :phones, presence: true
  validates :name, length: { maximum: 255 }, name: true, unless: :linked?
  validates :address, :city_title, :area, :street, address: true, unless: :linked?
  validates :room, :floor, numericality: { less_than: MAX_INTEGER, greater_than: 0 }, allow_blank: true
  validate :validate_house

  accepts_nested_attributes_for :emails, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true

  before_create do
    self.externalcode ||= SecureRandom.hex(16)
    rebuild_rfm
  end

  before_save :set_occupation_name, if: :will_save_change_to_occupation_id?

  before_create :set_category

  def category
    client_category
  end

  def to_s
    "##{id}"
  end

  def client_segment
    @client_segment ||= RFMAnalytics::ClientSegmentizer.new(vendor_rfm: vendor.rfm_segments, client: self).segmentize
  end

  def rebuild_rfm
    if persisted?
      update_columns(
        rfm_masks: client_segment.to_mask,
        rfm_segment_id: client_segment.segment.id
      )
    else
      assign_attributes(
        rfm_masks: client_segment.to_mask,
        rfm_segment_id: client_segment.segment.id
      )
    end
  end

  def recency
    return 0 if last_order_created_at.blank?

    Date.current - last_order_created_at.to_date
  end

  def rfm
    RFMAnalytics::ClientSegments.new(
      r: rfm_masks[0],
      f: rfm_masks[1],
      m: rfm_masks[2]
    )
  end

  def first_name
    super || name.split.first
  end

  def last_name
    second_name || name.split.last
  end

  def to_label
    "[##{id}] #{name}"
  end

  def email
    emails.first
  end

  def phone
    phones.first
  end

  def phones_array
    phones.collect(&:phone)
  end

  def emails_array
    emails.collect(&:email)
  end

  def confirm_phone!(phone)
    # TODO У одного клиента могут быть несколько телефонов с одним номером?
    phones.unconfirmed.where(phone: phone).find_each(&:confirm!)
  end

  def confirm_email!(email)
    # TODO У одного клиента могут быть несколько одинаковых email?
    emails.unconfirmed.where(email: email).find_each(&:confirm!)
  end

  def deliver_pin_code(phone)
    raise RequestTimeout, request_timeout unless can_resend?

    deliver_pin_code! phone
  end

  def send_email_confirmation(email)
    generate_email_confirmation_token! if email_confirmation_token.blank?
    url = Rails.application.routes.url_helpers.vendor_confirmation_url(id: email_confirmation_token, email: email, host: vendor.home_url)
    EmailConfirmationMailer.send_url(id, email, url).deliver
  end

  def send_reset_password(email)
    generate_reset_password_token! if reset_password_token.blank?
    url = Rails.application.routes.url_helpers.vendor_reset_password_url(id: reset_password_token, host: vendor.home_url)
    ClientResetPasswordMailer.send_instructions(id, email, url).deliver
  end

  def request_timeout
    return nil unless persisted?

    @request_timeout ||= build_timeout
  end

  def generate_reset_password_token!
    update reset_password_token: SecureRandom.hex(16)
  end

  def update_ms_counterparty
    MoyskladClientExportWorker.perform_async id if vendor.enable_ms_export_clients?
  end

  def full_info
    [first_name, second_name, phone, email].compact.join(' ')
  end

  def paid_orders_count
    orders.payed.count
  end

  def total_orders_discount_amount
    Money.new (orders.sum(:discount_price_cents) + orders.sum(:total_sale_amount_cents)), vendor.currency_iso_code
  end

  private

  def validate_house
    return if house.blank?

    errors.add :house, I18n.vt('errors.order.house') unless HOUSE_REGEXP.match(house)
  end

  def set_occupation_name
    self.occupation_name = occupation.name if occupation.present?
  end

  def set_category
    self.client_category = vendor.default_client_category
  end

  def deliver_pin_code!(phone)
    generate_pin_code!
    phone = phones.where(phone: Phoner::Phone.parse(phone).to_s).first!
    cabinet_url = Rails.application.routes.url_helpers.vendor_cabinet_url(host: vendor.home_url)

    # Отправляем SMS синхронно, чтобы можно было получить ошибку и показать пользователю
    SmsWorker.new.direct_perform(
      phone.to_s,
      I18n.t('services.client_pin_sender.sms_text', pin: reload.pin_code, cabinet_url: cabinet_url),
      vendor
    )
    @request_timeout = nil
    update_column :pin_requested_at, Time.zone.now
  end

  def generate_pin_code
    self.pin_code = rand(1000..9999)
  end

  def generate_email_confirmation_token!
    update email_confirmation_token: SecureRandom.hex(16)
  end

  def generate_pin_code!
    new_pin_code = generate_pin_code
    update_column :pin_code, new_pin_code
  end

  def can_resend?
    request_timeout.zero?
  end

  def build_timeout
    return 0 if pin_requested_at.blank?

    rt = (Time.zone.now - pin_requested_at).to_i
    return 0 if rt >= REQUEST_TIMEOUT

    REQUEST_TIMEOUT - rt
  end

  class RequestTimeout < StandardError
    attr_reader :timeout

    def initialize(timeout)
      @timeout = timeout
    end

    def message
      "Только что отправили SMS с кодом, дождитесь ее. Запросить код повторно сможете через #{I18n.t('operator.seconds_count', count: timeout)}."
    end
  end
end
