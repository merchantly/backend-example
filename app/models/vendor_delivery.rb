class VendorDelivery < ApplicationRecord
  extend Enumerize
  include Authority::Abilities

  include Archivable
  include Sortable

  include VendorDeliveryPayment
  include VendorDeliveryRestriction
  include VendorDeliveryValidation
  include VendorDeliveryInquirer

  belongs_to :vendor

  has_many :order_conditions, dependent: :destroy
  has_many :orders, foreign_key: :delivery_type_id
  has_many :delivery_cities, dependent: :delete_all, foreign_key: :delivery_id
  has_many :pickup_points, class_name: 'DeliveryPickupPoint'

  has_many :delivery_time_slots, dependent: :destroy
  has_many :delivery_time_periods, through: :delivery_time_slots
  has_many :delivery_time_rules, dependent: :destroy
  has_many :clients, dependent: :nullify

  scope :by_type, ->(type) { where delivery_agent_type: type.name }
  scope :not_by_type, ->(type) { where.not delivery_agent_type: type.name }
  scope :for_client, -> { ordered.alive }
  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  monetize :price_cents,
           as: :price,
           with_model_currency: :price_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, allow_nil: true, less_than: Settings.maximal_money }

  monetize :free_delivery_threshold_cents,
           as: :free_delivery_threshold,
           with_model_currency: :free_delivery_threshold_currency,
           allow_nil: true,
           numericality: { greater_than_or_equal_to: 0, allow_nil: true, less_than: Settings.maximal_money }

  before_validation on: :create do
    self.price_currency = vendor.try(:currency_iso_code)
    self.free_delivery_threshold_currency = vendor.try(:currency_iso_code)
  end

  # Уникальность отлкючили, потому что возникают проблемы с названиями уже удаленных оплат.
  # Нужно проверять на уникальность, только в мире живых. Не придумал как это сделать быстро.
  #
  # validates :title, uniqueness: { scope: :vendor_id }, if: :alive?

  delegate :selfdelivery?, :is_digital_only?, to: :agent
  delegate :tax_type, to: :vendor

  accepts_nested_attributes_for :delivery_time_rules, reject_if: :all_blank, allow_destroy: true

  enumerize :yandex_delivery_type, in: %w[pickup post todoor]
  enumerize :yandex_city_from, in: %w[Москва Санкт-Петербург]

  enumerize :russian_post_mail_category, in: RussianPost::MAIL_CATEGORIES
  enumerize :russian_post_mail_type, in: RussianPost::MAIL_TYPES

  def title
    super || agent_class.try(:humanized_name)
  end

  # Длжно быть после def title
  translates :title, :description, :city_title, :comment_field_title, :comment_field_placeholder, :mail_comment

  def to_label
    title
  end

  def default_comment_field_placeholder
    I18n.vt('order.fields.comment')
  end

  def default_comment_field_title
    I18n.vt('order.placeholders.comment')
  end

  def agent_class
    delivery_agent_type.try(:constantize)
  end

  def agent
    agent_class.new
  rescue NoMethodError
    raise "Unknown agent_class: '#{agent_class}'"
  end

  def pickup_address
    description
  end

  def to_s
    title
  end

  def default_delivery_time_rule
    delivery_time_rules.create_with(time: '00:00', to: '00:00').find_or_create_by!(is_default: true)
  end
end
