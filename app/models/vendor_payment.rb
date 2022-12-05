class VendorPayment < ApplicationRecord
  extend Enumerize
  include Authority::Abilities

  include Archivable
  include Sortable

  include VendorPaymentWalletone
  include VendorPaymentDelivery
  include VendorPaymentOnlineKassa
  include VendorPaymentKeys
  include VendorPaymentValidation
  include VendorPaymentInquirer

  strip_attributes only: :geidea_payment_merchant_id, collapse_spaces: true

  belongs_to :vendor
  has_many :orders, foreign_key: :payment_type_id, dependent: :destroy
  has_many :order_conditions, dependent: :destroy

  belongs_to :cashier, class_name: 'Ecr::Cashier'

  scope :by_type, ->(type) { where payment_agent_type: type.name }
  scope :for_client, -> { ordered.alive }
  scope :with_autocanceling, -> { where 'canceling_timeout_minutes > 0' }
  scope :by_title, ->(title) { where "? = ANY(avals(#{arel_table.name}.title_translations))", title }

  mount_uploader :geidea_merchant_logo, ImageUploader

  validates :cashier_id, uniqueness: { scope: :vendor_id }, allow_blank: true if IntegrationModules.enable?(:ecr)

  def title
    super || agent_class.try(:humanized_name)
  end

  # Длжно быть после def title
  translates :title, :description, :content

  def to_label
    title
  end

  def agent_class
    payment_agent_type.try(:constantize)
  end

  def agent
    agent_class.new
  end

  def icon_url
    "/images/payment_icons/#{payment_agent_type.underscore}.png"
  end

  def to_s
    title
  end

  def discount_for_delivery(vendor_delivery)
    payment_to_deliveries.with_discount.find_by(vendor_delivery: vendor_delivery)
  end
end
